# output "key_vault_id" {
#   value = azurerm_key_vault.this.id
# }
#
# output "key_vault_uri" {
#   value = azurerm_key_vault.this.vault_uri
# }
#
# output "key_vault_name" {
#   value = azurerm_key_vault.this.name
# }
#
# output "root_ca_id" {
#   value       = azurerm_key_vault_certificate.root_ca.id
#   description = "ID del certificato root CA — da esportare e consegnare agli enti"
# }
#
# output "root_ca_thumbprint" {
#   value       = azurerm_key_vault_certificate.root_ca.thumbprint
#   description = "Thumbprint SHA1 della root CA"
# }
#
# output "client_cert_ids" {
#   value = {
#     for k, v in azurerm_key_vault_certificate.client_certs : k => v.id
#   }
# }
#
# output "client_cert_secret_ids" {
#   value = {
#     for k, v in azurerm_key_vault_certificate.client_certs : k => v.secret_id
#   }
#   description = "Secret ID da usare nel CSI driver o nel riferimento Container Apps"
#   sensitive   = true
# }
