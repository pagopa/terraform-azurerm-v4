provider "azurerm" {
  features {}
}

variables {
  location = "westeurope"
  tags = {
    "Environment" = "test"
    "CreatedBy"  = "TerraformTest"
  }
  enable_resource_locks = true
  resource_group_prefix = "testpayment-domain1"
  additional_resource_groups = ["testpayment-domain1-custom-rg"]
}

run "verify_default_resource_groups_creation" {
  command = plan

  assert {
    condition = length(azurerm_resource_group.resource_groups) == 5
    error_message = "Expected 5 resource groups (4 default + 1 custom)"
  }

  assert {
    condition = contains(keys(azurerm_resource_group.resource_groups), "data")
    error_message = "Missing data resource group"
  }

  assert {
    condition = contains(keys(azurerm_resource_group.resource_groups), "security")
    error_message = "Missing security resource group"
  }

  assert {
    condition = contains(keys(azurerm_resource_group.resource_groups), "compute")
    error_message = "Missing compute resource group"
  }

  assert {
    condition = contains(keys(azurerm_resource_group.resource_groups), "identity")
    error_message = "Missing identity resource group"
  }
}

run "verify_resource_group_naming" {
  command = plan

  assert {
    condition = all(azurerm_resource_group.resource_groups["data"].name == "${var.resource_group_prefix}-data-rg")
    error_message = "Data resource group name is incorrect"
  }

  assert {
    condition = all(azurerm_resource_group.resource_groups["security"].name == "${var.resource_group_prefix}-security-rg")
    error_message = "Security resource group name is incorrect"
  }
}

run "verify_resource_locks" {
  command = plan

  assert {
    condition = length(azurerm_management_lock.resource_group_lock) == 5
    error_message = "Expected resource locks on all resource groups when enabled"
  }

  assert {
    condition = all(azurerm_management_lock.resource_group_lock[*].lock_level == "CanNotDelete")
    error_message = "Resource locks should be CanNotDelete"
  }
}

run "verify_tags" {
  command = plan

  assert {
    condition = all([for rg in azurerm_resource_group.resource_groups : contains(keys(rg.tags), "Environment")])
    error_message = "Environment tag is missing from resource groups"
  }

  assert {
    condition = all([for rg in azurerm_resource_group.resource_groups : contains(keys(rg.tags), "CreatedBy")])
    error_message = "CreatedBy tag is missing from resource groups"
  }
}
