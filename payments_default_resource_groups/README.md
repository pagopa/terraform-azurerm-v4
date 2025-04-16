# Azure Resource Groups Module

This Terraform module manages Azure resource groups with predefined defaults and support for additional custom resource groups.

## Features

- Creates a set of default resource groups for common infrastructure patterns:
  - Data resource group (`-data-rg`)
  - Security resource group (`-security-rg`)
  - Compute resource group (`-compute-rg`)
  - CICD resource group (`-cicd-rg`)
- Supports adding custom resource groups beyond the defaults
- Consistent naming convention using prefix and environment
- Flexible tagging system with base and additional tags
- Input validation for resource group name lengths

## Requirements

- Terraform >= 1.3.0
- AzureRM provider

## Usage

### Basic Usage with Domain Setup

```hcl
locals {
  domains_setup = {
    "idpay" = {
      tags = {
        "CostCenter"    = "TS310 - PAGAMENTI & SERVIZI"
        "BusinessUnit"  = "CStar"
        "Owner"         = "CStar"
        "Environment"   = var.env
        "CreatedBy"     = "Terraform"
        "Source"        = "https://github.com/pagopa/cstar-securehub-infra"
        "domain"        = "idpay"
      }
      additional_resource_groups = [
        "${local.product_nodomain}-idpay-azdo-rg"
      ]
    }
  }
}

module "default_resource_groups" {
  source               = "git::https://github.com/pagopa/terraform-azurerm-v3.git//azure_default_resource_groups?ref=main"
  for_each = local.domains_setup

  resource_group_prefix = "${local.product_nodomain}-${each.key}"
  location             = var.location
  tags                 = merge(var.tags, each.value.tags)

  additional_resource_groups = can(each.value.additional_resource_groups) ? each.value.additional_resource_groups : []
}
```

### Multiple Domains Example

```hcl
locals {
  product_nodomain = "payment"
  domains_setup = {
    "idpay" = {
      tags = {
        "CostCenter"    = "TS310 - PAGAMENTI & SERVIZI"
        "BusinessUnit"  = "CStar"
        "Owner"         = "CStar"
        "Environment"   = var.env
        "CreatedBy"     = "Terraform"
        "domain"        = "idpay"
      }
      additional_resource_groups = [
        "${local.product_nodomain}-idpay-azdo-rg"
      ]
    }
    "wallet" = {
      tags = {
        "CostCenter"    = "TS310 - PAGAMENTI & SERVIZI"
        "BusinessUnit"  = "CStar"
        "Owner"         = "CStar"
        "Environment"   = var.env
        "CreatedBy"     = "Terraform"
        "domain"        = "wallet"
      }
    }
  }
}

module "default_resource_groups" {
  source = "./modules/azure_default_resource_groups"
  for_each = local.domains_setup

  resource_group_prefix = "${local.product_nodomain}-${each.key}"
  location             = var.location
  tags                 = merge(var.tags, each.value.tags)

  additional_resource_groups = can(each.value.additional_resource_groups) ? each.value.additional_resource_groups : []
}
```

<!-- markdownlint-disable -->
<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_management_lock.resource_group_lock](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/management_lock) | resource |
| [azurerm_resource_group.resource_groups](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_resource_groups"></a> [additional\_resource\_groups](#input\_additional\_resource\_groups) | List of additional resource groups to create besides the default ones | `list(string)` | `[]` | no |
| <a name="input_additional_tags"></a> [additional\_tags](#input\_additional\_tags) | Additional tags to be merged with the default tags | `map(string)` | `{}` | no |
| <a name="input_enable_resource_locks"></a> [enable\_resource\_locks](#input\_enable\_resource\_locks) | Whether to enable CanNotDelete locks on the resource groups | `bool` | `true` | no |
| <a name="input_location"></a> [location](#input\_location) | The Azure region where the resources should be created | `string` | n/a | yes |
| <a name="input_resource_group_prefix"></a> [resource\_group\_prefix](#input\_resource\_group\_prefix) | Prefix for the resource group names | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to be applied to the resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_resource_group_names"></a> [resource\_group\_names](#output\_resource\_group\_names) | Map of resource group names |
| <a name="output_resource_groups"></a> [resource\_groups](#output\_resource\_groups) | Map of all created resource groups with their properties |
<!-- END_TF_DOCS -->
