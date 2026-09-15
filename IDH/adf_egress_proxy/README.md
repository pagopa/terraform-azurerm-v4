# ADF egress proxy

This module creates a proxy that can be used by ADX clusters to reach private PostgreSQL databases in a private subnet. The proxy is deployed in a dedicated subnet and is associated with a NAT Gateway to allow outbound traffic to the internet.

This module creates:

- a VMSS with a single instance, running a proxy service that forwards traffic to the specified PostgreSQL databases
- a load balancer to distribute traffic and allow private link service access
- a private link service to allow the VMSS to be accessed from other virtual networks
- a keyvault secret (optional) to store the database hosts using format `db1-fqdn,db2-fqdn`. It can be useful to share the configuration with the module `adf_egress_connection`


## IDH resources available

[Here's](./LIBRARY.md) the list of `idh_resource_tiers` available for this module.

## How to use it

### Basic usage – single node pool with external subnet

```hcl
module "adf_proxy" {
  source = "./.terraform/modules/__v4__/IDH/adf_egress_proxy"
  # idh properties
  env = var.env
  idh_resource_tier = "small"
  product_name = var.prefix
  
  name = "${var.prefix}-${var.env_short}-adf-proxy"
  resource_group_name = azurerm_resource_group.rg_network.name

  database_adf_proxy_mapping = [
    {
      fqdn             = "idpay-db.${var.env_short}.internal.postgresql.cstar.pagopa.it"
      external_port    = 5432
      destination_port = 5432
    }
  ]

  vmss_credentials = {
    admin_login = data.azurerm_key_vault_secret.network_vmss_login.value
    admin_password = data.azurerm_key_vault_secret.network_vmss_password.value
  }

  vnet = {
    name = module.vnet_core_hub.name
    resource_group_name = module.vnet_core_hub.resource_group_name
  }

  output_kv = {
    name                = local.kv_core_name
    resource_group_name = local.kv_core_resource_group_name
    secret_name         = "${var.prefix}-${var.env_short}-adf-proxy-database-map"
  }
  
  tags = module.tag_config.tags
}
```

<!-- markdownlint-disable -->
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 4 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_idh_loader"></a> [idh\_loader](#module\_idh\_loader) | ../01_idh_loader | n/a |
| <a name="module_load_balancer_egress"></a> [load\_balancer\_egress](#module\_load\_balancer\_egress) | ../../load_balancer | n/a |
| <a name="module_vmss_pls_snet"></a> [vmss\_pls\_snet](#module\_vmss\_pls\_snet) | ../subnet | n/a |
| <a name="module_vmss_snet"></a> [vmss\_snet](#module\_vmss\_snet) | ../subnet | n/a |

## Resources

| Name | Type |
|------|------|
| [azurerm_key_vault_secret.output_database_map](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_secret) | resource |
| [azurerm_linux_virtual_machine_scale_set.vmss_egress](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_virtual_machine_scale_set) | resource |
| [azurerm_monitor_autoscale_setting.vmss_scale](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_autoscale_setting) | resource |
| [azurerm_private_link_service.vmss_pls](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_link_service) | resource |
| [azurerm_subnet_nat_gateway_association.vmss_snet_nat](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_nat_gateway_association) | resource |
| [azurerm_virtual_machine_scale_set_extension.vmss_extension](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_machine_scale_set_extension) | resource |
| [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) | data source |
| [azurerm_key_vault.output_kv](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/key_vault) | data source |
| [azurerm_nat_gateway.nat_gateway](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/nat_gateway) | data source |
| [azurerm_resource_group.resource_group](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/resource_group) | data source |
| [azurerm_virtual_network.vnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/virtual_network) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_database_adf_proxy_mapping"></a> [database\_adf\_proxy\_mapping](#input\_database\_adf\_proxy\_mapping) | (Required): List of database ADF proxy mappings. must contain the private FQDN of the database, the external port exposed by the proxy for ADF to connect to the database, and the destination port on the database to which ADF will connect through the egress proxy. | <pre>list(object({<br/>    fqdn             = string # private fqdn of the database to which the ADF will connect through the egress proxy<br/>    external_port    = number # port exposed by the proxy for the ADF to connect to the database<br/>    destination_port = number # port on the database to which the ADF will connect through the egress proxy<br/>  }))</pre> | n/a | yes |
| <a name="input_env"></a> [env](#input\_env) | (Required): Environment for which the resource will be created. | `string` | n/a | yes |
| <a name="input_idh_resource_tier"></a> [idh\_resource\_tier](#input\_idh\_resource\_tier) | (Required): The name of IDH resource tier to be created. | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | (Required): The name (including prefix) for the created resources | `string` | n/a | yes |
| <a name="input_nat_gateway"></a> [nat\_gateway](#input\_nat\_gateway) | (Optional): The name and resource group of the NAT gateway to be associated with the VMSS subnet. If not defined, no NAT gateway will be associated with the subnet. | <pre>object({<br/>    name                = string<br/>    resource_group_name = string<br/>  })</pre> | `null` | no |
| <a name="input_output_kv"></a> [output\_kv](#input\_output\_kv) | (Optional): The name and resource group of the Key Vault where the output database configuration will be stored. If not defined, no Key Vault will be used. | <pre>object({<br/>    name                = string # name of the keyvault where to save the output database configuration<br/>    resource_group_name = string # resource group of the keyvault where to save the output database configuration<br/>    secret_name         = string # name of the secret where to save the output database configuration<br/>  })</pre> | `null` | no |
| <a name="input_product_name"></a> [product\_name](#input\_product\_name) | (Required): Product name used to identify the platform for which the resource will be created. | `string` | n/a | yes |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | (Required): The name of the resource group in which to create the proxy resources. | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | (Optional): Map of tags to assign to the resource. | `map(any)` | n/a | yes |
| <a name="input_vmss_credentials"></a> [vmss\_credentials](#input\_vmss\_credentials) | (Required): The administrator login and password for the VMSS instances. | <pre>object({<br/>    admin_login    = string<br/>    admin_password = string<br/>  })</pre> | n/a | yes |
| <a name="input_vnet"></a> [vnet](#input\_vnet) | (Required): The name and resource group of the virtual network to which the VMSS subnet will be attached. | <pre>object({<br/>    name                = string<br/>    resource_group_name = string<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_database_map"></a> [database\_map](#output\_database\_map) | Map of database names to their corresponding connection strings and keys. |
| <a name="output_database_map_kv_secret_name"></a> [database\_map\_kv\_secret\_name](#output\_database\_map\_kv\_secret\_name) | n/a |
| <a name="output_load_balancer_id"></a> [load\_balancer\_id](#output\_load\_balancer\_id) | n/a |
| <a name="output_load_balancer_name"></a> [load\_balancer\_name](#output\_load\_balancer\_name) | n/a |
| <a name="output_load_balancer_rg"></a> [load\_balancer\_rg](#output\_load\_balancer\_rg) | n/a |
| <a name="output_vmss_id"></a> [vmss\_id](#output\_vmss\_id) | n/a |
| <a name="output_vmss_name"></a> [vmss\_name](#output\_vmss\_name) | n/a |
| <a name="output_vmss_pls_snet"></a> [vmss\_pls\_snet](#output\_vmss\_pls\_snet) | n/a |
| <a name="output_vmss_rg"></a> [vmss\_rg](#output\_vmss\_rg) | n/a |
| <a name="output_vmss_scale_id"></a> [vmss\_scale\_id](#output\_vmss\_scale\_id) | n/a |
| <a name="output_vmss_scale_name"></a> [vmss\_scale\_name](#output\_vmss\_scale\_name) | n/a |
| <a name="output_vmss_scale_rg"></a> [vmss\_scale\_rg](#output\_vmss\_scale\_rg) | n/a |
| <a name="output_vmss_snet"></a> [vmss\_snet](#output\_vmss\_snet) | n/a |
<!-- END_TF_DOCS -->
