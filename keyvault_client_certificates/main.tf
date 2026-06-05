locals {
  private_root_ca_name = "private-root-ca"
}

data "azurerm_key_vault_certificate" "root_ca" {
  name         = local.private_root_ca_name
  key_vault_id = var.root_key_vault_id
}

# Fires at (validity_months * 30 - renewal_days_before_expiry) days → reissues cert-foo
resource "time_rotating" "cert_rotation" {
  for_each         = var.certificates
  rotation_days    = var.rotation_minutes_override == null ? (each.value.validity_in_months * 30 - var.renewal_days_before_expiry) : null
  rotation_minutes = var.rotation_minutes_override
}

# Fires at (validity_months * 30 - stable_promotion_days_before_expiry) days → promotes cert-foo to cert-foo-stable
resource "time_rotating" "cert_stable" {
  for_each         = var.certificates
  rotation_days    = var.rotation_minutes_override == null ? (each.value.validity_in_months * 30 - var.stable_promotion_days_before_expiry) : null
  rotation_minutes = var.rotation_minutes_override
}

# Phase 1: emit / renew the current certificate (cert-foo)
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

# Phase 2: promote cert-foo to cert-foo-stable
# Runs on first creation and when time_rotating.cert_stable fires (Y days before expiry).
# depends_on ensures cert-foo exists before promotion.
resource "terraform_data" "client_cert_stable" {
  for_each = var.certificates

  depends_on = [terraform_data.client_cert_sign]

  triggers_replace = {
    stable_id = time_rotating.cert_stable[each.key].id
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<-BASH
      set -euo pipefail

      VENV_DIR="${path.module}/.venv-stable-${each.key}"
      trap "rm -rf \"$VENV_DIR\"" EXIT

      if [ ! -f "$VENV_DIR/bin/activate" ]; then
        echo "==> Creating virtualenv in $VENV_DIR..."
        python3 -m venv "$VENV_DIR"
        "$VENV_DIR/bin/pip" install --quiet --upgrade pip
        "$VENV_DIR/bin/pip" install --quiet \
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
