# Azure Resource Groups Module

This Terraform module manages Azure resource groups with predefined defaults and support for additional custom resource groups.

## Features

- Creates a set of default resource groups for common infrastructure patterns:
  - Data resource group (`-data-rg`)
  - Security resource group (`-security-rg`)
  - Compute resource group (`-compute-rg`)
  - Identity resource group (`-identity-rg`)
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
  source = "./modules/azure_default_resource_groups"
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
<!-- END_TF_DOCS -->
