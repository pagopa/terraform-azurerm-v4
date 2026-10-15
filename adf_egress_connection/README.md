# ADF egress connection

This module creates a ADF managed private endpoint to the private link service provided, configuring it to resolve the database hosts defined in the provided mapping.

The database mapping is defined in the following format: `db1-fqdn,db2-fqdn`


## How to use it

### Basic usage – single node pool with external subnet

```hcl
module "adf_egress_vmss_connection" {
  source = "./.terraform/modules/__v4__/adf_egress_connection"

  data_factory_id = module.data_factory.id
  egress_proxy_pls_id = data.azurerm_private_link_service.vmss_pls.id

  adf_database_mapping = data.azurerm_key_vault_secret.adf_database_map.value
}
```

<!-- markdownlint-disable -->
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9.0 |
| <a name="requirement_azapi"></a> [azapi](#requirement\_azapi) | >= 2.6.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 4 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azapi_resource_action.approve_privatelink_private_endpoint_connection](https://registry.terraform.io/providers/azure/azapi/latest/docs/resources/resource_action) | resource |
| [azurerm_data_factory_managed_private_endpoint.private_endpoint](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/data_factory_managed_private_endpoint) | resource |
| [azapi_resource.privatelink_private_endpoint_connection](https://registry.terraform.io/providers/azure/azapi/latest/docs/data-sources/resource) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_adf_database_mapping"></a> [adf\_database\_mapping](#input\_adf\_database\_mapping) | (Required): Comma-separated list of FQDNs for the databases that the Azure Data Factory will connect to through the managed private endpoint. | `string` | n/a | yes |
| <a name="input_data_factory_id"></a> [data\_factory\_id](#input\_data\_factory\_id) | (Required): The ID of the Azure Data Factory instance to which the managed private endpoint will be associated. | `string` | n/a | yes |
| <a name="input_egress_proxy_pls_id"></a> [egress\_proxy\_pls\_id](#input\_egress\_proxy\_pls\_id) | (Required): The ID of the Private Link Service (PLS) for the egress proxy to which the managed private endpoint will connect. | `string` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
