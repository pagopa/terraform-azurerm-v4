resource "azurerm_data_factory_managed_private_endpoint" "proxy_private_endpoint" {
  count = var.egress_proxy_pls_id != null ? 1 : 0
  name               = "AzureDataFactoryToVMSSProxy"
  data_factory_id    = var.data_factory_id
  target_resource_id = var.egress_proxy_pls_id
  fqdns              = [for pg in var.adf_linked_service_postgresql : pg.host]
}


moved {
  from = azurerm_data_factory_managed_private_endpoint.proxy_private_endpoint
  to   = azurerm_data_factory_managed_private_endpoint.proxy_private_endpoint[0]
}



data "azapi_resource" "privatelink_private_endpoint_connection" {
    count = var.egress_proxy_pls_id != null ? 1 : 0

  type                   = "Microsoft.Network/privateLinkServices@2022-09-01"
  resource_id            = var.egress_proxy_pls_id
  response_export_values = ["properties.privateEndpointConnections."]

  depends_on = [
    azurerm_data_factory_managed_private_endpoint.proxy_private_endpoint
  ]
}

locals {
  privatelink_private_endpoint_connection_name = var.egress_proxy_pls_id != null ? data.azapi_resource.privatelink_private_endpoint_connection[0].output.properties.privateEndpointConnections[0].name : ""
}


moved {
  from = azapi_resource_action.approve_privatelink_private_endpoint_connection
  to   = azapi_resource_action.approve_privatelink_private_endpoint_connection[0]
}

resource "azapi_resource_action" "approve_privatelink_private_endpoint_connection" {
    count = var.egress_proxy_pls_id != null ? 1 : 0

  type        = "Microsoft.Network/privateLinkServices/privateEndpointConnections@2022-09-01"
  resource_id = "${var.egress_proxy_pls_id}/privateEndpointConnections/${local.privatelink_private_endpoint_connection_name}"
  method      = "PUT"

  body = {
    properties = {
      privateLinkServiceConnectionState = {
        description = "Approved via Terraform - ${azurerm_data_factory_managed_private_endpoint.proxy_private_endpoint[0].name}" # To identify which managed private endpoint this connection belongs to we add the managed private endpoint name to the description
        status      = "Approved"
      }
    }
  }
}
