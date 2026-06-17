############################################################
# Storage Account for Static Website (Optional)
############################################################

locals {
  storage_account_name = try(var.storage_account.account_name, null) != null ? replace(var.storage_account.account_name, "-", "") : replace("${var.profile.name}sa", "-", "")
  create_storage       = try(var.storage_account.enabled, false)

  # Static-website storage account exposed as a CDN Front Door origin.
  # The origin is wired automatically only when the storage is enabled AND an
  # origin_group is provided to attach it to.
  storage_origin_key     = "storage-static-website"
  storage_origin_enabled = local.create_storage && try(var.storage_account.origin_group, null) != null
  storage_origin_host    = one(module.storage_account[*].primary_web_host)
}

############################################################
# Storage Account (static website)
############################################################
/* Provisions a secure Storage Account configured for static website hosting */
module "storage_account" {
  source = "../storage_account"
  count  = local.create_storage ? 1 : 0

  name                            = local.storage_account_name
  resource_group_name             = var.resource_group_name
  location                        = var.location
  account_kind                    = var.storage_account.account_kind
  account_tier                    = var.storage_account.account_tier
  account_replication_type        = var.storage_account.account_replication_type
  access_tier                     = var.storage_account.access_tier
  blob_versioning_enabled         = true
  allow_nested_items_to_be_public = var.storage_account.allow_nested_items_to_be_public
  public_network_access_enabled   = var.storage_account.public_network_access
  advanced_threat_protection      = var.storage_account.threat_protection_enabled
  index_document                  = var.storage_account.index_document
  error_404_document              = var.storage_account.error_404_document
  tags                            = var.tags
}