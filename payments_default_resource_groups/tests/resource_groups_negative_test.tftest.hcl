provider "azurerm" {
  features {}
}

variables {
  location = "westeurope"
  tags = {}  # Empty tags to test behavior
  enable_resource_locks = false  # Disable locks to test that scenario
  resource_group_prefix = "testpayment-domain1"
  additional_resource_groups = []  # No additional groups
}

run "verify_no_locks_when_disabled" {
  command = plan

  assert {
    condition = length(azurerm_management_lock.resource_group_lock) == 0
    error_message = "Should not create locks when disabled"
  }
}

run "verify_minimum_default_groups" {
  command = plan

  assert {
    condition = length(azurerm_resource_group.resource_groups) == 4
    error_message = "Should create exactly 4 default resource groups"
  }
}

run "verify_empty_tags_behavior" {
  command = plan

  assert {
    condition = alltrue([
      for rg in azurerm_resource_group.resource_groups :
      length(rg.tags) == 0
    ])
    error_message = "Resource groups should have no tags when none provided"
  }
}
