output "ca_key_vault_name" {
  value = module.private_ca.key_vault_name
}

output "client_key_vault_name" {
  value = module.kv_client.name
}

output "certificate_chain_pem" {
  value = module.client_certificate.certificate_chain_pem
}

output "root_ca_pem" {
  value = module.client_certificate.root_ca_pem
}
