output "access_policy_id" {
  description = "L'ID della policy creata"
  value       = azurerm_key_vault_access_policy.this.id
}
