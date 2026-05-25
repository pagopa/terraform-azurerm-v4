#!/usr/bin/env python3
"""
sign_cert.py — Sign a client certificate via Azure Key Vault HSM.

Flow:
  1. Create a "pending" certificate in KV (issuer=Unknown) → get the CSR
  2. Build the TBS certificate with all X.509 fields
  3. Sign the SHA-256 digest of TBS via KV key sign (CA key never leaves vault)
  4. Assemble the final DER certificate (TBS + AlgoID + signature)
  5. Merge in KV → bind signed cert to internal private key
  6. Export the PFX (cert + private key) and save it as secret in KV

Dependencies:
  pip install cryptography azure-identity azure-keyvault-certificates \
              azure-keyvault-keys azure-keyvault-secrets

Usage:
  python3 sign_cert.py \
    --vault-name   "my-keyvault" \
    --cert-name    "client-service-a" \
    --subject      "CN=service-a,O=DevOpsLabs,C=IT" \
    --validity     12 \
    --ca-cert-name "private-root-ca" \
    --san-dns      "service-a.internal,service-a.svc.cluster.local"
"""

import argparse
import base64
import datetime
import hashlib
import json
import logging
import sys
import time
from typing import Optional

from azure.identity import DefaultAzureCredential
from azure.keyvault.certificates import (
    CertificateClient,
    CertificatePolicy,
    CertificateContentType,
    KeyType,
    KeyUsageType,
    WellKnownIssuerNames,
)
from azure.keyvault.keys import KeyClient
from azure.keyvault.keys.crypto import CryptographyClient, SignatureAlgorithm
from azure.keyvault.secrets import SecretClient

from cryptography import x509
from cryptography.hazmat.backends import default_backend
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import rsa
from cryptography.x509.oid import ExtendedKeyUsageOID

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    datefmt="%H:%M:%S",
)
log = logging.getLogger(__name__)

logging.getLogger("azure").setLevel(logging.WARNING)
logging.getLogger("azure.core.pipeline.policies.http_logging_policy").setLevel(logging.WARNING)
logging.getLogger("azure.identity").setLevel(logging.WARNING)

# ---------------------------------------------------------------------------
# Minimal ASN.1 DER helpers (no dependency on asn1crypto)
# ---------------------------------------------------------------------------

def _asn1_length(n: int) -> bytes:
    if n < 0x80:
        return bytes([n])
    elif n < 0x100:
        return bytes([0x81, n])
    elif n < 0x10000:
        return bytes([0x82, (n >> 8) & 0xFF, n & 0xFF])
    else:
        raise ValueError(f"ASN.1 length too large: {n}")


def _encode_sequence(content: bytes) -> bytes:
    return b"\x30" + _asn1_length(len(content)) + content


def _encode_bitstring(data: bytes) -> bytes:
    """BIT STRING with zero padding bits (0x00 prefix)."""
    content = b"\x00" + data
    return b"\x03" + _asn1_length(len(content)) + content


def _parse_asn1_length(data: bytes, offset: int):
    """Returns (length, new_offset)."""
    first = data[offset]
    if first < 0x80:
        return first, offset + 1
    nb = first & 0x7F
    length = int.from_bytes(data[offset + 1 : offset + 1 + nb], "big")
    return length, offset + 1 + nb


def extract_tbs_der(cert_der: bytes) -> bytes:
    """
    Extracts the raw TBSCertificate (DER) from a complete DER certificate.
    Structure: SEQUENCE { TBSCertificate, AlgorithmIdentifier, BIT STRING }
    """
    assert cert_der[0] == 0x30, "Certificate does not start with SEQUENCE"
    _, inner_start = _parse_asn1_length(cert_der, 1)

    assert cert_der[inner_start] == 0x30, "TBSCertificate is not a SEQUENCE"
    tbs_len, tbs_content_start = _parse_asn1_length(cert_der, inner_start + 1)
    return cert_der[inner_start : tbs_content_start + tbs_len]


# AlgorithmIdentifier per sha256WithRSAEncryption (OID 1.2.840.113549.1.1.11)
SHA256_RSA_ALGO_ID = bytes([
    0x30, 0x0D,
    0x06, 0x09,
    0x2A, 0x86, 0x48, 0x86, 0xF7, 0x0D, 0x01, 0x01, 0x0B,
    0x05, 0x00,
])


def assemble_certificate_der(tbs_der: bytes, signature: bytes) -> bytes:
    """Assemble the final certificate DER: SEQUENCE { TBS, AlgoID, BIT STRING }."""
    return _encode_sequence(
        tbs_der + SHA256_RSA_ALGO_ID + _encode_bitstring(signature)
    )


def der_to_pem(der: bytes, label: str = "CERTIFICATE") -> str:
    b64 = base64.b64encode(der).decode()
    lines = [b64[i : i + 64] for i in range(0, len(b64), 64)]
    return f"-----BEGIN {label}-----\n" + "\n".join(lines) + f"\n-----END {label}-----\n"


# ---------------------------------------------------------------------------
# Main logic
# ---------------------------------------------------------------------------

def build_tbs_der(
    csr: x509.CertificateSigningRequest,
    ca_cert: x509.Certificate,
    validity_months: int,
    san_dns_names: list[str],
) -> bytes:
    """
    Build the TBSCertificate and return it in DER format.
    Uses a temporary local RSA key only to get the DER structure:
    the CA's private key is NEVER used here.
    """
    now = datetime.datetime.utcnow().replace(microsecond=0)
    expiry = now + datetime.timedelta(days=validity_months * 30)
    serial = x509.random_serial_number()

    builder = (
        x509.CertificateBuilder()
        .subject_name(csr.subject)
        .issuer_name(ca_cert.subject)
        .public_key(csr.public_key())
        .serial_number(serial)
        .not_valid_before(now)
        .not_valid_after(expiry)
        .add_extension(
            x509.BasicConstraints(ca=False, path_length=None),
            critical=True,
        )
        .add_extension(
            x509.KeyUsage(
                digital_signature=True,
                key_encipherment=True,
                content_commitment=False,
                key_agreement=False,
                key_cert_sign=False,
                crl_sign=False,
                data_encipherment=False,
                encipher_only=False,
                decipher_only=False,
            ),
            critical=True,
        )
        .add_extension(
            x509.ExtendedKeyUsage([ExtendedKeyUsageOID.CLIENT_AUTH]),
            critical=False,
        )
        .add_extension(
            x509.SubjectKeyIdentifier.from_public_key(csr.public_key()),
            critical=False,
        )
        .add_extension(
            x509.AuthorityKeyIdentifier.from_issuer_public_key(ca_cert.public_key()),
            critical=False,
        )
    )

    if san_dns_names:
        builder = builder.add_extension(
            x509.SubjectAlternativeName(
                [x509.DNSName(d.strip()) for d in san_dns_names if d.strip()]
            ),
            critical=False,
        )

    # Dummy signature with local temporary key to get the structured DER
    tmp_key = rsa.generate_private_key(65537, 2048, default_backend())
    dummy_cert = builder.sign(tmp_key, hashes.SHA256(), default_backend())
    cert_der = dummy_cert.public_bytes(serialization.Encoding.DER)

    return extract_tbs_der(cert_der)


def wait_for_pending_cert(cert_client: CertificateClient, cert_name: str, timeout: int = 120):
    """Wait for the pending certificate to be available and return the CSR."""
    deadline = time.time() + timeout
    while time.time() < deadline:
        try:
            op = cert_client.get_certificate_operation(cert_name)
            if op.csr:
                return bytes(op.csr)  # bytes DER of CSR
        except Exception:
            pass
        log.info("  Waiting for CSR to be available...")
        time.sleep(3)
    raise TimeoutError(f"CSR not available within {timeout}s for '{cert_name}'")


def sign_cert(
    ca_vault_url: str,
    vault_url: str,
    cert_name: str,
    subject: str,
    validity_months: int,
    ca_cert_name: str,
    san_dns_names: list[str],
    tags: Optional[dict] = None,
) -> None:
    credential = DefaultAzureCredential()

    # Two separate clients: one for CA vault (source), one for cert vault (destination)
    ca_cert_client  = CertificateClient(vault_url=ca_vault_url, credential=credential)
    ca_key_client   = KeyClient(vault_url=ca_vault_url, credential=credential)

    cert_client    = CertificateClient(vault_url=vault_url, credential=credential)
    secret_client  = SecretClient(vault_url=vault_url, credential=credential)

    # ------------------------------------------------------------------
    # Step 1 — Create pending certificate in KV (issuer=Unknown)
    #          KV generates internal RSA key and produces the CSR
    # ------------------------------------------------------------------
    log.info("[1/5] Creating pending certificate '%s' in Key Vault...", cert_name)

    policy = CertificatePolicy(
        issuer_name=WellKnownIssuerNames.unknown,
        subject=subject,
        exportable=True,                       # client key extractable for PFX
        key_type=KeyType.rsa,
        key_size=2048,
        reuse_key=False,
        content_type=CertificateContentType.pkcs12,
        validity_in_months=validity_months,
        key_usage=[
            KeyUsageType.digital_signature,
            KeyUsageType.key_encipherment,
        ],
        enhanced_key_usage=["1.3.6.1.5.5.7.3.2"],  # clientAuth
    )

    cert_client.begin_create_certificate(cert_name, policy, tags=tags)
    log.info("  Pending certificate created, retrieving CSR...")

    csr_der = wait_for_pending_cert(cert_client, cert_name)
    csr_pem = der_to_pem(csr_der, "CERTIFICATE REQUEST").encode()
    csr = x509.load_pem_x509_csr(csr_pem, default_backend())
    log.info("  CSR obtained: subject=%s", csr.subject.rfc4514_string())

    # ------------------------------------------------------------------
    # Step 2 — Download the public cert of root CA from source KV
    # ------------------------------------------------------------------
    log.info("[2/5] Downloading root CA public certificate '%s'...", ca_cert_name)

    ca_cert_bundle = ca_cert_client.get_certificate(ca_cert_name)
    ca_cert_der = bytes(ca_cert_bundle.cer)  # bytes DER of public certificate
    ca_cert = x509.load_der_x509_certificate(ca_cert_der, default_backend())
    log.info("  Root CA: subject=%s", ca_cert.subject.rfc4514_string())

    # ------------------------------------------------------------------
    # Step 3 — Build TBS and compute SHA-256 digest
    # ------------------------------------------------------------------
    log.info("[3/5] Building TBS certificate and computing SHA-256 digest...")

    tbs_der = build_tbs_der(csr, ca_cert, validity_months, san_dns_names)
    digest = hashlib.sha256(tbs_der).digest()
    log.info("  TBS: %d bytes | SHA-256 digest: %s", len(tbs_der), digest.hex()[:16] + "...")

    # ------------------------------------------------------------------
    # Step 4 — Sign via source KV key sign (CA key remains in HSM)
    # ------------------------------------------------------------------
    log.info("[4/5] Signing digest via KV key sign (CA key remains in vault)...")

    ca_key = ca_key_client.get_key(ca_cert_name)  # same name as cert, from source vault
    crypto_client = CryptographyClient(ca_key, credential=credential)

    sign_result = crypto_client.sign(SignatureAlgorithm.rs256, digest)
    signature = sign_result.signature
    log.info("  Signature obtained: %d bytes", len(signature))

    # ------------------------------------------------------------------
    # Step 5 — Assemble DER, merge in KV, export PFX
    # ------------------------------------------------------------------
    log.info("[5/5] Assembling final certificate and merging in Key Vault...")

    cert_der = assemble_certificate_der(tbs_der, signature)
    cert_pem = der_to_pem(cert_der).encode()

    # Basic check: the cryptography library must be able to parse it
    signed_cert = x509.load_der_x509_certificate(cert_der, default_backend())
    log.info(
        "  Certificate assembled: serial=%s | valid until %s",
        hex(signed_cert.serial_number),
        signed_cert.not_valid_after,
    )

    # Merge in KV: bind the signed certificate to the internal private key
    cert_client.merge_certificate(cert_name, [cert_der])
    log.info("  Merge completed — certificate bound to private key in KV.")

    # Export the PFX by reading the KV secret (contains cert + private key)
    # The secret has the same name as the certificate
    secret = secret_client.get_secret(cert_name)
    pfx_b64 = secret.value  # base64-encoded PKCS#12

    # Save the PFX as a new dedicated secret: "<cert-name>-pfx"
    pfx_secret_name = f"{cert_name}-pfx"
    secret_client.set_secret(
        pfx_secret_name,
        pfx_b64,
        content_type="application/x-pkcs12",
        tags=tags,
    )
    log.info(
        "  PFX saved as KV secret (name omitted) (base64, %d chars).",
        len(pfx_b64),
    )

    log.info("==> Completed: certificate '%s' signed and available in Key Vault.", cert_name)


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def parse_args():
    p = argparse.ArgumentParser(
        description="Sign a client certificate via Azure Key Vault HSM."
    )
    p.add_argument("--ca-vault-name",   required=True, help="Name of the Key Vault containing Root CA (without .vault.azure.net)")
    p.add_argument("--vault-name",      required=True, help="Name of the Key Vault for client certificate (without .vault.azure.net)")
    p.add_argument("--cert-name",       required=True, help="Name of the client certificate to create in KV")
    p.add_argument("--subject",         required=True, help="Subject DN, e.g. 'CN=service-a,O=Acme,C=IT'")
    p.add_argument("--validity",        required=True, type=int, help="Validity in months")
    p.add_argument("--ca-cert-name",    required=True, help="Name of the root CA certificate in source KV")
    p.add_argument("--san-dns",         default="",    help="SAN DNS names separated by comma")
    p.add_argument("--tags", required=True, help="JSON string of tags to apply (e.g. '{\"env\":\"prod\")')")
    return p.parse_args()


def main():
    args = parse_args()
    ca_vault_url = f"https://{args.ca_vault_name}.vault.azure.net"
    vault_url = f"https://{args.vault_name}.vault.azure.net"
    san_dns = [s.strip() for s in args.san_dns.split(",") if s.strip()]

    # Parse tags from JSON string to dict
    try:
        tags = json.loads(args.tags) if args.tags else {}
        if not isinstance(tags, dict):
            raise ValueError("tags must be a JSON object (dictionary)")
    except json.JSONDecodeError as e:
        log.error("Error parsing tags JSON: %s", e)
        sys.exit(1)

    log.info("CA Vault  : %s", ca_vault_url)
    log.info("Cert Vault: %s", vault_url)
    log.info("Cert      : %s", args.cert_name)
    log.info("Subject   : %s", args.subject)
    log.info("Validity  : %d months", args.validity)
    log.info("CA cert   : %s", args.ca_cert_name)
    log.info("SAN DNS   : %s", san_dns or "(none)")
    if tags:
        log.info("Tags      : %s", tags)

    try:
        sign_cert(
            ca_vault_url=ca_vault_url,
            vault_url=vault_url,
            cert_name=args.cert_name,
            subject=args.subject,
            validity_months=args.validity,
            ca_cert_name=args.ca_cert_name,
            san_dns_names=san_dns,
            tags=tags,
        )
    except Exception as exc:
        log.error("ERROR: %s", exc, exc_info=True)
        sys.exit(1)


if __name__ == "__main__":
    main()
