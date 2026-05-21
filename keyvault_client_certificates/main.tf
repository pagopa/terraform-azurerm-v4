locals {
  private_root_ca_name = "private-root-ca"
}

data "azurerm_key_vault_certificate" "root_ca" {
  name         = local.private_root_ca_name
  key_vault_id = var.key_vault_id
}

resource "terraform_data" "client_cert_sign" {
  for_each = var.certificates

  depends_on = [data.azurerm_key_vault_certificate.root_ca]
  triggers_replace = {
    ca_thumbprint      = data.azurerm_key_vault_certificate.root_ca.thumbprint
    subject            = each.value.subject
    validity_in_months = each.value.validity_in_months
    san_dns_names      = each.value.san_dns_names
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<-BASH
      set -euo pipefail

      VENV_DIR="${path.module}/.venv"

      if [ ! -f "$VENV_DIR/bin/activate" ]; then
        echo "==> Creazione virtualenv in $VENV_DIR..."
        python3 -m venv "$VENV_DIR"
        "$VENV_DIR/bin/pip" install --quiet --upgrade pip
        "$VENV_DIR/bin/pip" install --quiet \
          cryptography \
          azure-identity \
          azure-keyvault-certificates \
          azure-keyvault-keys \
          azure-keyvault-secrets
        echo "    Virtualenv pronto."
      fi

      "$VENV_DIR/bin/python" ${path.module}/scripts/sign_cert.py \
        --vault-name   "${var.key_vault_name}" \
        --cert-name    "${each.key}" \
        --subject      "${each.value.subject}" \
        --validity     "${each.value.validity_in_months}" \
        --ca-cert-name "${data.azurerm_key_vault_certificate.root_ca.name}" \
        --san-dns      "${join(",", each.value.san_dns_names)}"
    BASH
  }
}