#!/usr/bin/env python3
"""
sign_cert.py — Firma un certificato client tramite Azure Key Vault HSM.

Flusso:
  1. Crea un certificato "pending" in KV (issuer=Unknown) → ottiene la CSR
  2. Costruisce il TBS certificate con tutti i campi X.509
  3. Firma il digest SHA-256 del TBS tramite KV key sign (chiave CA non esce mai dal vault)
  4. Assembla il certificato DER finale (TBS + AlgoID + firma)
  5. Fa il merge in KV → abbina cert firmato alla chiave privata interna
  6. Esporta il PFX (cert + chiave privata) e lo salva come secret in KV

Dipendenze:
  pip install cryptography azure-identity azure-keyvault-certificates \
              azure-keyvault-keys azure-keyvault-secrets

Uso:
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
# ASN.1 DER helpers minimali (nessuna dipendenza da asn1crypto)
# ---------------------------------------------------------------------------

def _asn1_length(n: int) -> bytes:
    if n < 0x80:
        return bytes([n])
    elif n < 0x100:
        return bytes([0x81, n])
    elif n < 0x10000:
        return bytes([0x82, (n >> 8) & 0xFF, n & 0xFF])
    else:
        raise ValueError(f"Lunghezza ASN.1 troppo grande: {n}")


def _encode_sequence(content: bytes) -> bytes:
    return b"\x30" + _asn1_length(len(content)) + content


def _encode_bitstring(data: bytes) -> bytes:
    """BIT STRING con zero padding bits (prefisso 0x00)."""
    content = b"\x00" + data
    return b"\x03" + _asn1_length(len(content)) + content


def _parse_asn1_length(data: bytes, offset: int):
    """Restituisce (length, new_offset)."""
    first = data[offset]
    if first < 0x80:
        return first, offset + 1
    nb = first & 0x7F
    length = int.from_bytes(data[offset + 1 : offset + 1 + nb], "big")
    return length, offset + 1 + nb


def extract_tbs_der(cert_der: bytes) -> bytes:
    """
    Estrae il TBSCertificate grezzo (DER) da un certificato DER completo.
    Struttura: SEQUENCE { TBSCertificate, AlgorithmIdentifier, BIT STRING }
    """
    assert cert_der[0] == 0x30, "Il certificato non inizia con SEQUENCE"
    _, inner_start = _parse_asn1_length(cert_der, 1)

    assert cert_der[inner_start] == 0x30, "TBSCertificate non è una SEQUENCE"
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
    """Assembla il certificato DER finale: SEQUENCE { TBS, AlgoID, BIT STRING }."""
    return _encode_sequence(
        tbs_der + SHA256_RSA_ALGO_ID + _encode_bitstring(signature)
    )


def der_to_pem(der: bytes, label: str = "CERTIFICATE") -> str:
    b64 = base64.b64encode(der).decode()
    lines = [b64[i : i + 64] for i in range(0, len(b64), 64)]
    return f"-----BEGIN {label}-----\n" + "\n".join(lines) + f"\n-----END {label}-----\n"


# ---------------------------------------------------------------------------
# Logica principale
# ---------------------------------------------------------------------------

def build_tbs_der(
    csr: x509.CertificateSigningRequest,
    ca_cert: x509.Certificate,
    validity_months: int,
    san_dns_names: list[str],
) -> bytes:
    """
    Costruisce il TBSCertificate e lo restituisce in DER.
    Usa una chiave RSA temporanea locale solo per ottenere la struttura DER:
    la chiave privata della CA NON viene mai usata qui.
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

    # Firma dummy con chiave temporanea locale per ottenere il DER strutturato
    tmp_key = rsa.generate_private_key(65537, 2048, default_backend())
    dummy_cert = builder.sign(tmp_key, hashes.SHA256(), default_backend())
    cert_der = dummy_cert.public_bytes(serialization.Encoding.DER)

    return extract_tbs_der(cert_der)


def wait_for_pending_cert(cert_client: CertificateClient, cert_name: str, timeout: int = 120):
    """Attende che il certificato pending sia disponibile e restituisce la CSR."""
    deadline = time.time() + timeout
    while time.time() < deadline:
        try:
            op = cert_client.get_certificate_operation(cert_name)
            if op.csr:
                return op.csr  # bytes DER della CSR
        except Exception:
            pass
        log.info("  In attesa che la CSR sia disponibile...")
        time.sleep(3)
    raise TimeoutError(f"CSR non disponibile entro {timeout}s per '{cert_name}'")


def sign_cert(
    vault_url: str,
    cert_name: str,
    subject: str,
    validity_months: int,
    ca_cert_name: str,
    san_dns_names: list[str],
    tags: Optional[dict] = None,
) -> None:
    credential = DefaultAzureCredential()

    cert_client    = CertificateClient(vault_url=vault_url, credential=credential)
    key_client     = KeyClient(vault_url=vault_url, credential=credential)
    secret_client  = SecretClient(vault_url=vault_url, credential=credential)

    # ------------------------------------------------------------------
    # Step 1 — Crea certificato pending in KV (issuer=Unknown)
    #          KV genera chiave RSA interna e produce la CSR
    # ------------------------------------------------------------------
    log.info("[1/5] Creazione certificato pending '%s' in Key Vault...", cert_name)

    policy = CertificatePolicy(
        issuer_name=WellKnownIssuerNames.unknown,
        subject=subject,
        exportable=True,                       # chiave client estraibile per il PFX
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
    log.info("  Certificato pending creato, recupero CSR...")

    csr_der = wait_for_pending_cert(cert_client, cert_name)
    csr_pem = der_to_pem(csr_der, "CERTIFICATE REQUEST").encode()
    csr = x509.load_pem_x509_csr(csr_pem, default_backend())
    log.info("  CSR ottenuta: subject=%s", csr.subject.rfc4514_string())

    # ------------------------------------------------------------------
    # Step 2 — Scarica il cert pubblico della root CA da KV
    # ------------------------------------------------------------------
    log.info("[2/5] Download certificato pubblico root CA '%s'...", ca_cert_name)

    ca_cert_bundle = cert_client.get_certificate(ca_cert_name)
    ca_cert_der = ca_cert_bundle.cer  # bytes DER del certificato pubblico
    ca_cert = x509.load_der_x509_certificate(ca_cert_der, default_backend())
    log.info("  Root CA: subject=%s", ca_cert.subject.rfc4514_string())

    # ------------------------------------------------------------------
    # Step 3 — Costruisce TBS e calcola digest SHA-256
    # ------------------------------------------------------------------
    log.info("[3/5] Costruzione TBS certificate e calcolo digest SHA-256...")

    tbs_der = build_tbs_der(csr, ca_cert, validity_months, san_dns_names)
    digest = hashlib.sha256(tbs_der).digest()
    log.info("  TBS: %d bytes | digest SHA-256: %s", len(tbs_der), digest.hex()[:16] + "...")

    # ------------------------------------------------------------------
    # Step 4 — Firma tramite KV key sign (chiave CA resta nell'HSM)
    # ------------------------------------------------------------------
    log.info("[4/5] Firma del digest tramite KV key sign (CA key rimane nel vault)...")

    ca_key = key_client.get_key(ca_cert_name)  # stesso nome del cert
    crypto_client = CryptographyClient(ca_key, credential=credential)

    sign_result = crypto_client.sign(SignatureAlgorithm.rs256, digest)
    signature = sign_result.signature
    log.info("  Firma ottenuta: %d bytes", len(signature))

    # ------------------------------------------------------------------
    # Step 5 — Assembla DER, merge in KV, esporta PFX
    # ------------------------------------------------------------------
    log.info("[5/5] Assemblaggio certificato finale e merge in Key Vault...")

    cert_der = assemble_certificate_der(tbs_der, signature)
    cert_pem = der_to_pem(cert_der).encode()

    # Verifica base: la libreria cryptography deve riuscire a parsarlo
    signed_cert = x509.load_der_x509_certificate(cert_der, default_backend())
    log.info(
        "  Certificato assemblato: serial=%s | valido fino a %s",
        hex(signed_cert.serial_number),
        signed_cert.not_valid_after,
    )

    # Merge in KV: abbina il certificato firmato alla chiave privata interna
    cert_client.merge_certificate(cert_name, [cert_der])
    log.info("  Merge completato — certificato abbinato alla chiave privata in KV.")

    # Esporta il PFX leggendo il secret KV (contiene cert + chiave privata)
    # Il secret ha lo stesso nome del certificato
    secret = secret_client.get_secret(cert_name)
    pfx_b64 = secret.value  # base64-encoded PKCS#12

    # Salva il PFX come nuovo secret dedicato: "<cert-name>-pfx"
    pfx_secret_name = f"{cert_name}-pfx"
    secret_client.set_secret(
        pfx_secret_name,
        pfx_b64,
        content_type="application/x-pkcs12",
        tags=tags,
    )
    log.info(
        "  PFX salvato come secret KV '%s' (base64, %d chars).",
        pfx_secret_name,
        len(pfx_b64),
    )

    log.info("==> Completato: certificato '%s' firmato e disponibile in Key Vault.", cert_name)


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def parse_args():
    p = argparse.ArgumentParser(
        description="Firma un certificato client tramite Azure Key Vault HSM."
    )
    p.add_argument("--vault-name",   required=True, help="Nome del Key Vault (senza .vault.azure.net)")
    p.add_argument("--cert-name",    required=True, help="Nome del certificato client da creare in KV")
    p.add_argument("--subject",      required=True, help="Subject DN, es. 'CN=service-a,O=Acme,C=IT'")
    p.add_argument("--validity",     required=True, type=int, help="Validità in mesi")
    p.add_argument("--ca-cert-name", required=True, help="Nome del certificato root CA in KV")
    p.add_argument("--san-dns",      default="",    help="SAN DNS names separati da virgola")
    p.add_argument("--tags", default="{}", help="JSON string dei tag da applicare")  # <--- Aggiungi questo
    return p.parse_args()


def main():
    args = parse_args()
    vault_url = f"https://{args.vault_name}.vault.azure.net"
    san_dns = [s.strip() for s in args.san_dns.split(",") if s.strip()]

    log.info("Vault : %s", vault_url)
    log.info("Cert  : %s", args.cert_name)
    log.info("Subject: %s", args.subject)
    log.info("Validity: %d mesi", args.validity)
    log.info("CA cert: %s", args.ca_cert_name)
    log.info("SAN DNS: %s", san_dns or "(nessuno)")

    try:
        sign_cert(
            vault_url=vault_url,
            cert_name=args.cert_name,
            subject=args.subject,
            validity_months=args.validity,
            ca_cert_name=args.ca_cert_name,
            san_dns_names=san_dns,
        )
    except Exception as exc:
        log.error("ERRORE: %s", exc, exc_info=True)
        sys.exit(1)


if __name__ == "__main__":
    main()
