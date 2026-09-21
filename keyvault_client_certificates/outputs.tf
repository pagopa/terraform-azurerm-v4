output "certificate_chain_pem" {
  description = "Full PEM chain (current leaf certificate followed by the root CA) per certificate name. Only populated for certificates declaring key_vault_id."
  value       = local.certificate_chain_pem
}

output "root_ca_pem" {
  description = "Public certificate of the private root CA, in PEM format."
  value       = local.root_ca_pem
}
