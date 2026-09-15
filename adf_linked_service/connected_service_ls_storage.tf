#linked service for blob storage
resource "azurerm_data_factory_linked_service_azure_blob_storage" "df_connection_linked_service_blob" {
  for_each          = var.adf_linked_services_blob
  name              = "${each.key}-blob-${var.env_short}-ls"
  data_factory_id   = var.data_factory_id
  connection_string = each.value.connection_string

  integration_runtime_name = local.df_integration_runtime_name
  use_managed_identity     = true

  lifecycle {
    ignore_changes = [
      connection_string_insecure,
      connection_string
    ]
  }

}

