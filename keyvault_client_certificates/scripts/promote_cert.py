#!/usr/bin/env python3
"""
promote_cert.py — Promote <cert-name> to <cert-name>-stable in Azure Key Vault.

Reads the PFX secret <cert-name>-pfx and writes three stable secrets:
  - <cert-name>-stable-pfx   : full PKCS#12 (base64)
  - <cert-name>-stable-key   : private key PEM (PKCS8, no encryption)
  - <cert-name>-stable-cert  : public certificate PEM

Usage:
  python3 promote_cert.py \
    --vault-name "my-keyvault" \
    --cert-name  "client-service-a" \
    --tags       '{"env":"prod"}'
"""

import argparse
import base64
import json
import logging
import sys

from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient

from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.serialization.pkcs12 import load_key_and_certificates

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    datefmt="%H:%M:%S",
)
log = logging.getLogger(__name__)

logging.getLogger("azure").setLevel(logging.WARNING)
logging.getLogger("azure.identity").setLevel(logging.WARNING)


def promote(vault_url: str, cert_name: str, tags: dict) -> None:
    credential = DefaultAzureCredential()
    secret_client = SecretClient(vault_url=vault_url, credential=credential)

    # ------------------------------------------------------------------
    # Step 1 — Read and decompose the PFX
    # ------------------------------------------------------------------
    src_name = f"{cert_name}-pfx"
    log.info("[1/3] Reading PFX secret '%s'...", src_name)
    pfx_b64 = secret_client.get_secret(src_name).value
    pfx_bytes = base64.b64decode(pfx_b64)

    private_key, certificate, _ = load_key_and_certificates(pfx_bytes, password=None)

    key_pem = private_key.private_bytes(
        encoding=serialization.Encoding.PEM,
        format=serialization.PrivateFormat.PKCS8,
        encryption_algorithm=serialization.NoEncryption(),
    ).decode()

    cert_pem = certificate.public_bytes(serialization.Encoding.PEM).decode()

    log.info(
        "  PFX decomposed — cert serial: %s, valid until: %s",
        hex(certificate.serial_number),
        certificate.not_valid_after,
    )

    # ------------------------------------------------------------------
    # Step 2 — Write the three stable secrets
    # ------------------------------------------------------------------
    secrets = [
        (f"{cert_name}-stable-pfx",  pfx_b64,  "application/x-pkcs12"),
        (f"{cert_name}-stable-key",  key_pem,  None),
        (f"{cert_name}-stable-cert", cert_pem, None),
    ]

    for i, (name, value, content_type) in enumerate(secrets, start=2):
        log.info("[%d/4] Writing secret '%s'...", i, name)
        secret_client.set_secret(name, value, content_type=content_type, tags=tags)

    log.info("==> Completed: '%s' promoted to stable (pfx + key + cert).", cert_name)


def parse_args():
    p = argparse.ArgumentParser(
        description="Promote a KV PFX secret to its stable variants (pfx, key, cert)."
    )
    p.add_argument("--vault-name", required=True, help="Key Vault name (without .vault.azure.net)")
    p.add_argument("--cert-name",  required=True, help="Certificate name (without suffixes)")
    p.add_argument("--tags",       required=True, help="JSON string of tags")
    return p.parse_args()


def main():
    args = parse_args()
    vault_url = f"https://{args.vault_name}.vault.azure.net"

    try:
        tags = json.loads(args.tags) if args.tags else {}
        if not isinstance(tags, dict):
            raise ValueError("tags must be a JSON object")
    except json.JSONDecodeError as e:
        log.error("Error parsing tags JSON: %s", e)
        sys.exit(1)

    log.info("Vault   : %s", vault_url)
    log.info("Source  : %s-pfx", args.cert_name)
    log.info("Stable  : %s-stable-pfx / %s-stable-key / %s-stable-cert",
             args.cert_name, args.cert_name, args.cert_name)
    if tags:
        log.info("Tags    : %s", tags)

    try:
        promote(vault_url, args.cert_name, tags)
    except Exception as exc:
        log.error("ERROR: %s", exc, exc_info=True)
        sys.exit(1)


if __name__ == "__main__":
    main()
