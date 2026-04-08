output "realm_ids" {
  description = "Map of Keycloak realm IDs indexed by realm name"
  value       = { for name, realm in keycloak_realm.this : name => realm.id }
}

output "realm_names" {
  description = "Map of Keycloak realm names indexed by realm name"
  value       = { for name, realm in keycloak_realm.this : name => name }
}