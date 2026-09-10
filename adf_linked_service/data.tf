data "azurerm_client_config" "current" {}

data "azurerm_key_vault_secret" "df_connection_postgres_host" {
  for_each     = var.adf_linked_service_postgresql
  name         = each.value.host_secret_name
  key_vault_id = each.value.key_vault_id
}

data "azurerm_key_vault_secret" "df_connection_postgres_port" {
  for_each     = var.adf_linked_service_postgresql
  name         = each.value.port_secret_name
  key_vault_id = each.value.key_vault_id
}

data "azurerm_key_vault_secret" "df_connection_postgres_database" {
  for_each     = var.adf_linked_service_postgresql
  name         = each.value.database_secret_name
  key_vault_id = each.value.key_vault_id
}

data "azurerm_key_vault_secret" "df_connection_postgres_username" {
  for_each     = var.adf_linked_service_postgresql
  name         = each.value.username_secret_name
  key_vault_id = each.value.key_vault_id
}
