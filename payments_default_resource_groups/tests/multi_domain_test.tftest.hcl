provider "azurerm" {
  features {}
}

variables {
  domains_setup = {
    "domain1" = {
      resource_group_prefix = "testpayment-domain1"
      location = "westeurope"
      tags = {
        "Environment" = "test"
        "Domain" = "domain1"
      }
      additional_resource_groups = ["testpayment-domain1-custom-rg"]
    }
    "domain2" = {
      resource_group_prefix = "testpayment-domain2"
      location = "westeurope"
      tags = {
        "Environment" = "test"
        "Domain" = "domain2"
      }
      additional_resource_groups = []
    }
  }
}

run "verify_multiple_domains" {
  command = plan

  assert {
    condition = length([
      for domain in var.domains_setup :
      azurerm_resource_group.resource_groups[domain]
    ]) == 8  # 4 default groups * 2 domains
    error_message = "Should create 4 default resource groups for each domain"
  }
}

run "verify_domain_specific_tags" {
  command = plan

  assert {
    condition = alltrue([
      for domain, rgs in azurerm_resource_group.resource_groups :
      contains(keys(rgs.tags), "Domain") &&
      rgs.tags["Domain"] == domain
    ])
    error_message = "Each resource group should have the correct domain tag"
  }
}

run "verify_custom_groups_per_domain" {
  command = plan

  assert {
    condition = length(azurerm_resource_group.resource_groups["domain1"]) == 5 &&
                length(azurerm_resource_group.resource_groups["domain2"]) == 4
    error_message = "Domain1 should have 5 groups (4 default + 1 custom), Domain2 should have 4 default groups"
  }
}

run "verify_resource_group_naming_across_domains" {
  command = plan

  assert {
    condition = alltrue([
      for domain, config in var.domains_setup :
      all(azurerm_resource_group.resource_groups[domain][*].name,
          startswith(config.resource_group_prefix))
    ])
    error_message = "Resource group names should start with their domain prefix"
  }
}
