#!/usr/bin/env bash
# Entrypoint immagine sync: az cli + jq
# Login gestito tramite Managed Identity (User Assigned) del Container App Job
set -euo pipefail

: "${SOURCE_ACR:?SOURCE_ACR non impostata}"
: "${BACKUP_ACR:?BACKUP_ACR non impostata}"
: "${MSI_CLIENT_ID:?MSI_CLIENT_ID non impostata}"

az login --identity -u $MSI_CLIENT_ID >/dev/null

echo "[*] Repo su $SOURCE_ACR..."
repos=$(az acr repository list --name "$SOURCE_ACR" -o tsv)

for repo in $repos; do
  echo "[*] Repo: $repo"

  # Digest già presenti nel backup, per evitare re-import inutili
  backup_digests=$(az acr repository show-manifests \
    --name "$BACKUP_ACR" --repository "$repo" \
    --query "[].digest" -o tsv 2>/dev/null || echo "")

  tags=$(az acr repository show-tags --name "$SOURCE_ACR" --repository "$repo" -o tsv)

  for tag in $tags; do
    digest=$(az acr repository show \
      --name "$SOURCE_ACR" --image "${repo}:${tag}" \
      --query "digest" -o tsv)

    if echo "$backup_digests" | grep -q "$digest"; then
      echo "    - ${repo}:${tag} già presente (digest invariato), skip"
      continue
    fi

    echo "    - import ${repo}:${tag}"
    az acr import \
      --name "$BACKUP_ACR" \
      --source "${SOURCE_ACR}.azurecr.io/${repo}:${tag}" \
      --image "${repo}:${tag}" \
      --force
  done
done

echo "[*] Sync completato."
