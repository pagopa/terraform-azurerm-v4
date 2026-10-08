#!/usr/bin/env bash
#
# check_cert_promotion.sh — Compare the current certificate (<name>-pfx) with
# the promoted one (<name>-stable-key + <name>-stable-cert) in Azure Key Vault.
#
# Exit codes:
#   0  same certificate: current and stable match, nothing to promote
#   1  different certificate: current was renewed and is not promoted yet
#      (also when the stable secrets do not exist)
#   2  error (az / openssl failure, stable key and cert not matching each other)
#
# Requires: az (logged in), openssl

set -euo pipefail

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
KEY_VAULT_NAME="pagopa-d-nodo-kv"
CERT_NAME="abc"
SUBSCRIPTION="DEV-PAGOPA" # optional: az account set -s "$SUBSCRIPTION"

# ---------------------------------------------------------------------------

umask 077 # private keys are written to disk
WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT

fail() {
  echo "ERROR: $*" >&2
  exit 2
}

# Prints a secret value; returns 1 when the secret does not exist.
get_secret() {
  local name=$1 out
  # stderr kept apart: az warnings must not end up in the secret value
  if ! out=$(az keyvault secret show --vault-name "$KEY_VAULT_NAME" --name "$name" --query value -o tsv 2>"$WORKDIR/az.err"); then
    if grep -q "SecretNotFound" "$WORKDIR/az.err"; then
      return 1
    fi
    fail "cannot read secret '$name': $(cat "$WORKDIR/az.err")"
  fi
  printf '%s' "$out"
}

# PFX exported by Key Vault has no password. OpenSSL 3 needs -legacy for
# older PKCS#12 algorithms; LibreSSL (macOS) does not know the flag.
p12() {
  local file=$1
  shift
  openssl pkcs12 -in "$file" -passin pass: "$@" 2>/dev/null ||
    openssl pkcs12 -legacy -in "$file" -passin pass: "$@" 2>/dev/null
}

cert_fingerprint() { openssl x509 -in "$1" -noout -fingerprint -sha256 | cut -d= -f2; }
cert_serial() { openssl x509 -in "$1" -noout -serial | cut -d= -f2; }
cert_not_after() { openssl x509 -in "$1" -noout -enddate | cut -d= -f2; }
cert_pubkey_hash() { openssl x509 -in "$1" -noout -pubkey | openssl pkey -pubin -outform DER | openssl dgst -sha256 -r | cut -d' ' -f1; }
key_pubkey_hash() { openssl pkey -in "$1" -pubout -outform DER | openssl dgst -sha256 -r | cut -d' ' -f1; }

if [[ -n "${SUBSCRIPTION:-}" ]]; then
  az account set -s "$SUBSCRIPTION"
fi

echo "==> Key Vault: $KEY_VAULT_NAME, certificate: $CERT_NAME"

# ---------------------------------------------------------------------------
# Current: <name>-pfx
# ---------------------------------------------------------------------------
rc=0
pfx_b64=$(get_secret "${CERT_NAME}-pfx") || rc=$?
case $rc in
0) ;;
1) fail "secret '${CERT_NAME}-pfx' not found" ;;
*) exit 2 ;;
esac
printf '%s' "$pfx_b64" | openssl base64 -d -A >"$WORKDIR/current.pfx"

p12 "$WORKDIR/current.pfx" -nokeys -clcerts | openssl x509 -out "$WORKDIR/current-cert.pem" 2>/dev/null ||
  fail "cannot extract the certificate from '${CERT_NAME}-pfx'"
p12 "$WORKDIR/current.pfx" -nocerts -nodes | openssl pkey -out "$WORKDIR/current-key.pem" 2>/dev/null ||
  fail "cannot extract the private key from '${CERT_NAME}-pfx'"

# ---------------------------------------------------------------------------
# Stable: <name>-stable-key + <name>-stable-cert
# ---------------------------------------------------------------------------
rc_cert=0
rc_key=0
stable_cert=$(get_secret "${CERT_NAME}-stable-cert") || rc_cert=$?
stable_key=$(get_secret "${CERT_NAME}-stable-key") || rc_key=$?
((rc_cert <= 1 && rc_key <= 1)) || exit 2
if ((rc_cert == 1 || rc_key == 1)); then
  echo "==> Stable secrets not found: certificate never promoted."
  echo "RESULT: DIFFERENT"
  exit 1
fi
printf '%s\n' "$stable_cert" >"$WORKDIR/stable-cert.pem"
printf '%s\n' "$stable_key" >"$WORKDIR/stable-key.pem"

openssl x509 -in "$WORKDIR/stable-cert.pem" -noout 2>/dev/null || fail "'${CERT_NAME}-stable-cert' is not a valid PEM certificate"
openssl pkey -in "$WORKDIR/stable-key.pem" -noout 2>/dev/null || fail "'${CERT_NAME}-stable-key' is not a valid PEM private key"

# ---------------------------------------------------------------------------
# Compare
# ---------------------------------------------------------------------------
current_fp=$(cert_fingerprint "$WORKDIR/current-cert.pem")
stable_fp=$(cert_fingerprint "$WORKDIR/stable-cert.pem")
current_key=$(key_pubkey_hash "$WORKDIR/current-key.pem")
stable_key_hash=$(key_pubkey_hash "$WORKDIR/stable-key.pem")
stable_cert_key=$(cert_pubkey_hash "$WORKDIR/stable-cert.pem")

# The stable pair must be consistent on its own, whatever current is
[[ "$stable_key_hash" == "$stable_cert_key" ]] ||
  fail "'${CERT_NAME}-stable-key' does not match '${CERT_NAME}-stable-cert'"

printf '\n%-8s serial %s, expires %s\n' "current" "$(cert_serial "$WORKDIR/current-cert.pem")" "$(cert_not_after "$WORKDIR/current-cert.pem")"
printf '%-8s serial %s, expires %s\n\n' "stable" "$(cert_serial "$WORKDIR/stable-cert.pem")" "$(cert_not_after "$WORKDIR/stable-cert.pem")"

if [[ "$current_fp" == "$stable_fp" && "$current_key" == "$stable_key_hash" ]]; then
  echo "RESULT: SAME (stable is up to date with current)"
  exit 0
fi

[[ "$current_fp" != "$stable_fp" ]] && echo "- certificate differs (fingerprint)"
[[ "$current_key" != "$stable_key_hash" ]] && echo "- private key differs"
echo "RESULT: DIFFERENT (current was renewed, stable not promoted yet)"
exit 1
