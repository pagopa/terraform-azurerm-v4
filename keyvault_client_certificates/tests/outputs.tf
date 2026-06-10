output "ca_key_vault_name" {
  value = module.private_ca.key_vault_name
}

output "client_key_vault_name" {
  value = module.kv_client.name
}
