locals {
  private_root_ca_name = "private-root-ca"

  # Effective promotion id per certificate, from exactly one source: the
  # stable_promotion_id in certificates, or var.stable_promotion_ids (passed by
  # pipelines at apply time). Mixing them is rejected by validation: once a run
  # omits stable_promotion_ids, the id would fall back to the one in
  # certificates, change, and promote again.
  stable_promotion_id = {
    for name, cert in var.certificates :
    name => lookup(var.stable_promotion_ids, name, cert.stable_promotion_id)
  }
}

data "azurerm_key_vault_certificate" "root_ca" {
  name         = local.private_root_ca_name
  key_vault_id = var.root_key_vault_id
}

# Fires at (validity_months * 30 - renewal_days_before_expiry) days → reissues
resource "time_rotating" "cert_rotation" {
  for_each = var.certificates

  rotation_days = each.value.validity_in_months * 30 - each.value.renewal_days_before_expiry

  # For testing only: overrides rotation_days with rotation_minutes
  # rotation_days    = var.rotation_minutes_override == null ? (each.value.validity_in_months * 30 - each.value.renewal_days_before_expiry) : null
  # rotation_minutes = var.rotation_minutes_override
}

# Phase 1: emit / renew the current certificate
resource "terraform_data" "client_cert_sign" {
  for_each = var.certificates

  depends_on = [data.azurerm_key_vault_certificate.root_ca]

  triggers_replace = {
    ca_thumbprint      = data.azurerm_key_vault_certificate.root_ca.thumbprint
    subject            = each.value.subject
    validity_in_months = each.value.validity_in_months
    san_dns_names      = join(",", each.value.san_dns_names)
    rotation_id        = time_rotating.cert_rotation[each.key].id
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<-BASH
      set -euo pipefail

      VENV_DIR="${path.module}/.venv-${each.key}"

      # Ensure cleanup on any exit (success or failure)
      trap "rm -rf \"$VENV_DIR\"" EXIT

      if [ ! -f "$VENV_DIR/bin/activate" ]; then
        echo "==> Creating virtualenv in $VENV_DIR..."
        python3 -m venv "$VENV_DIR"
        "$VENV_DIR/bin/pip" install --quiet --upgrade pip
        "$VENV_DIR/bin/pip" install --quiet \
          cryptography==41.0.7 \
          azure-identity==1.14.0 \
          azure-keyvault-certificates==4.7.0 \
          azure-keyvault-keys==4.7.0 \
          azure-keyvault-secrets==4.7.0
        echo "    Virtualenv ready."
      fi

      "$VENV_DIR/bin/python" ${path.module}/scripts/sign_cert.py \
        --ca-vault-name    "${var.root_key_vault_name}" \
        --vault-name       "${each.value.key_vault_name}" \
        --cert-name        "${each.key}" \
        --subject          "${each.value.subject}" \
        --validity         "${each.value.validity_in_months}" \
        --ca-cert-name     "${data.azurerm_key_vault_certificate.root_ca.name}" \
        --san-dns          "${join(",", each.value.san_dns_names)}" \
        --tags             '${jsonencode(var.tags != null ? var.tags : {})}'
    BASH
  }
}

# Phase 2: promote cert to cert-stable
# Manual only: runs whenever the certificate's promotion id
# (local.stable_promotion_id) changes to a new non-null value; with a null id
# it never promotes, so a renewal alone never reaches the stable secrets.
# A failed promotion leaves the resource tainted, so the next apply retries it.
# depends_on ensures certificate exists before promotion.
resource "terraform_data" "client_cert_stable" {
  for_each = var.certificates

  depends_on = [terraform_data.client_cert_sign]

  triggers_replace = {
    promotion_id = local.stable_promotion_id[each.key]
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<-BASH
      set -euo pipefail

      %{~if local.stable_promotion_id[each.key] == null~}
      echo "==> No stable_promotion_id set for '${each.key}', skipping promotion."
      exit 0
      %{~else~}
      echo "==> Promoting '${each.key}' to stable (promotion id: ${local.stable_promotion_id[each.key]})..."
      %{~endif~}

      VENV_DIR="${path.module}/.venv-stable-${each.key}"

      # Ensure cleanup on any exit (success or failure)
      trap "rm -rf \"$VENV_DIR\"" EXIT

      if [ ! -f "$VENV_DIR/bin/activate" ]; then
        echo "==> Creating virtualenv in $VENV_DIR..."
        python3 -m venv "$VENV_DIR"
        "$VENV_DIR/bin/pip" install --quiet --upgrade pip
        "$VENV_DIR/bin/pip" install --quiet \
          cryptography==41.0.7 \
          azure-identity==1.14.0 \
          azure-keyvault-secrets==4.7.0
        echo "    Virtualenv ready."
      fi

      "$VENV_DIR/bin/python" ${path.module}/scripts/promote_cert.py \
        --vault-name  "${each.value.key_vault_name}" \
        --cert-name   "${each.key}" \
        --tags        '${jsonencode(var.tags != null ? var.tags : {})}'
    BASH
  }
}

# Cleanup: runs destroy provisioner only when a certificate is removed from var.certificates.
# Uses input (not triggers_replace) so it is never replaced on rotation — only truly destroyed.
resource "terraform_data" "client_cert_sign_cleanup" {
  for_each = var.certificates

  input = {
    key_vault_name = each.value.key_vault_name
    cert_name      = each.key
  }

  provisioner "local-exec" {
    when        = destroy
    interpreter = ["/bin/bash", "-c"]
    command     = <<-BASH
      set -euo pipefail
      az keyvault certificate delete \
        --vault-name "${self.input.key_vault_name}" \
        --name       "${self.input.cert_name}" || true
      az keyvault secret delete \
        --vault-name "${self.input.key_vault_name}" \
        --name       "${self.input.cert_name}-pfx" || true
    BASH
  }
}

resource "terraform_data" "client_cert_stable_cleanup" {
  for_each = var.certificates

  input = {
    key_vault_name = each.value.key_vault_name
    cert_name      = each.key
  }

  provisioner "local-exec" {
    when        = destroy
    interpreter = ["/bin/bash", "-c"]
    command     = <<-BASH
      set -euo pipefail
      az keyvault secret delete \
        --vault-name "${self.input.key_vault_name}" \
        --name       "${self.input.cert_name}-stable-pfx" || true
      az keyvault secret delete \
        --vault-name "${self.input.key_vault_name}" \
        --name       "${self.input.cert_name}-stable-key" || true
      az keyvault secret delete \
        --vault-name "${self.input.key_vault_name}" \
        --name       "${self.input.cert_name}-stable-cert" || true
    BASH
  }
}
