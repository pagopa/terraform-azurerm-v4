#!/usr/bin/env python3
"""
promote_cert.py — Promote <cert-name>-pfx to <cert-name>-stable-pfx in Azure Key Vault.

Reads the PFX secret <cert-name>-pfx and writes it as <cert-name>-stable-pfx,
creating a new version if the stable secret already exists.

Usage:
  python3 promote_cert.py \
    --vault-name "my-keyvault" \
    --cert-name  "client-service-a" \
    --tags       '{"env":"prod"}'
"""

import argparse
import json
import logging
import sys

from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient

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

    src_name = f"{cert_name}-pfx"
    dst_name = f"{cert_name}-stable-pfx"

    log.info("[1/2] Reading PFX secret '%s'...", src_name)
    secret = secret_client.get_secret(src_name)
    log.info("  Secret read (%d chars).", len(secret.value))

    log.info("[2/2] Writing to stable secret '%s'...", dst_name)
    secret_client.set_secret(
        dst_name,
        secret.value,
        content_type="application/x-pkcs12",
        tags=tags,
    )
    log.info("==> Completed: '%s' promoted to '%s'.", src_name, dst_name)


def parse_args():
    p = argparse.ArgumentParser(
        description="Promote a KV PFX secret to its stable variant."
    )
    p.add_argument("--vault-name", required=True, help="Key Vault name (without .vault.azure.net)")
    p.add_argument("--cert-name",  required=True, help="Certificate name (without -pfx suffix)")
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

    log.info("Vault : %s", vault_url)
    log.info("Source: %s-pfx", args.cert_name)
    log.info("Dest  : %s-stable-pfx", args.cert_name)
    if tags:
        log.info("Tags  : %s", tags)

    try:
        promote(vault_url, args.cert_name, tags)
    except Exception as exc:
        log.error("ERROR: %s", exc, exc_info=True)
        sys.exit(1)


if __name__ == "__main__":
    main()
