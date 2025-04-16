locals {

  default_resource_groups = {
    data     = "${var.resource_group_prefix}-data-rg"
    security = "${var.resource_group_prefix}-security-rg"
    compute  = "${var.resource_group_prefix}-compute-rg"
    cicd     = "${var.resource_group_prefix}-cicd-rg"
  }

  # Merge default and additional resource groups
  all_resource_groups = merge(
    local.default_resource_groups,
    { for name in var.additional_resource_groups : name => name }
  )
}

resource "azurerm_resource_group" "resource_groups" {
  for_each = local.all_resource_groups

  name     = each.value
  location = var.location
  tags     = merge(var.tags, var.additional_tags)
}

# Add CanNotDelete locks to resource groups if enabled
resource "azurerm_management_lock" "resource_group_lock" {
  for_each = var.enable_resource_locks ? local.all_resource_groups : {}

  name       = "${each.value}-lock"
  scope      = azurerm_resource_group.resource_groups[each.key].id
  lock_level = "CanNotDelete"
  notes      = "This Resource Group is locked and cannot be deleted"

  depends_on = [azurerm_resource_group.resource_groups]
}

