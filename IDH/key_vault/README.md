# KeyVault

This module allow the creation of keyvault

## IDH resources available
[Here's](./LIBRARY.md) the list of `idh_resources_tiers` available for this module



## How to use it

```hcl
module "keyvault" {
  source = "./.terraform/modules/__v4__/IDH/key_vault"

  idh_resource_tier = "standard"
  product_name = var.product_name
  env = var.env

  name                = "${local.product}-test-kv"
  location = var.location
  resource_group_name = azurerm_resource_group.storage_rg.name
  tenant_id = data.azurerm_subscription.current.tenant_id

  tags = var.tags
}
```

<!-- markdownlint-disable -->
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 4 |
| <a name="requirement_null"></a> [null](#requirement\_null) | ~> 3.2 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_idh_loader"></a> [idh\_loader](#module\_idh\_loader) | ../01_idh_loader | n/a |
| <a name="module_key_vault"></a> [key\_vault](#module\_key\_vault) | ../../key_vault | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_env"></a> [env](#input\_env) | (Required) Environment for which the resource will be created | `string` | n/a | yes |
| <a name="input_idh_resource_tier"></a> [idh\_resource\_tier](#input\_idh\_resource\_tier) | (Required) The name od IDH resource key to be created. | `string` | n/a | yes |
| <a name="input_location"></a> [location](#input\_location) | n/a | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | n/a | `string` | n/a | yes |
| <a name="input_product_name"></a> [product\_name](#input\_product\_name) | (Required) product\_name used to identify the platform for which the resource will be created | `string` | n/a | yes |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | n/a | `string` | n/a | yes |
| <a name="input_sec_log_analytics_workspace_id"></a> [sec\_log\_analytics\_workspace\_id](#input\_sec\_log\_analytics\_workspace\_id) | Log analytics workspace security (it should be in a different subscription). | `string` | `null` | no |
| <a name="input_sec_storage_id"></a> [sec\_storage\_id](#input\_sec\_storage\_id) | Storage Account security (it should be in a different subscription). | `string` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | n/a | `map(any)` | n/a | yes |
| <a name="input_tenant_id"></a> [tenant\_id](#input\_tenant\_id) | n/a | `string` | n/a | yes |
| <a name="input_terraform_cloud_object_id"></a> [terraform\_cloud\_object\_id](#input\_terraform\_cloud\_object\_id) | Terraform cloud object id to create its access policy. | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_id"></a> [id](#output\_id) | n/a |
| <a name="output_name"></a> [name](#output\_name) | n/a |
| <a name="output_resource_group_name"></a> [resource\_group\_name](#output\_resource\_group\_name) | n/a |
| <a name="output_vault_uri"></a> [vault\_uri](#output\_vault\_uri) | n/a |
<!-- END_TF_DOCS -->
