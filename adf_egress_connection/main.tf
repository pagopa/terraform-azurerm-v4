
resource "azurerm_data_factory_managed_private_endpoint" "private_endpoint" {
  name               = "AzureDataFactoryToVMSSProxy"
  data_factory_id    = var.data_factory_id
  target_resource_id = var.egress_proxy_pls_id
  fqdns              = split(",", var.adf_database_mapping)
}


data "azapi_resource" "privatelink_private_endpoint_connection" {
  type                   = "Microsoft.Network/privateLinkServices@2022-09-01"
  resource_id            = var.egress_proxy_pls_id
  response_export_values = ["properties.privateEndpointConnections."]

  depends_on = [
    azurerm_data_factory_managed_private_endpoint.private_endpoint
  ]
}

locals {
  privatelink_private_endpoint_connection_name = data.azapi_resource.privatelink_private_endpoint_connection.output.properties.privateEndpointConnections[0].name
}


resource "azapi_resource_action" "approve_privatelink_private_endpoint_connection" {
  type        = "Microsoft.Network/privateLinkServices/privateEndpointConnections@2022-09-01"
  resource_id = "${var.egress_proxy_pls_id}/privateEndpointConnections/${local.privatelink_private_endpoint_connection_name}"
  method      = "PUT"

  body = {
    properties = {
      privateLinkServiceConnectionState = {
        description = "Approved via Terraform - ${azurerm_data_factory_managed_private_endpoint.private_endpoint.name}" # To identify which managed private endpoint this connection belongs to we add the managed private endpoint name to the description
        status      = "Approved"
      }
    }
  }
}





