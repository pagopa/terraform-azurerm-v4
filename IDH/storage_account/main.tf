module "idh_loader" {
  source = "../00_idh_loader"

  prefix       = var.prefix
  env          = var.env
  idh_resource = var.idh_resource
  idh_category = "storage_account"
}

module "storage_account" {
  source = "../../storage_account"

  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name

  account_kind                  = module.idh_loader.idh_config.account_kind
  account_tier                  = module.idh_loader.idh_config.account_tier
  account_replication_type      = module.idh_loader.idh_config.account_replication_type
  advanced_threat_protection    = module.idh_loader.idh_config.advanced_threat_protection
  public_network_access_enabled = module.idh_loader.idh_config.public_network_access_enabled

  blob_versioning_enabled         = module.idh_loader.idh_config.blob_versioning_enabled
  allow_nested_items_to_be_public = module.idh_loader.idh_config.allow_nested_items_to_be_public
  enable_low_availability_alert   = module.idh_loader.idh_config.enable_low_availability_alert
  tags                            = var.tags

  # it needs to be higher than the other retention policies
  blob_delete_retention_days           = module.idh_loader.idh_config.point_in_time_retention_days + 1
  blob_change_feed_enabled             = module.idh_loader.idh_config.blob_change_feed_enabled
  blob_change_feed_retention_in_days   = var.point_in_time_restore_enabled && module.idh_loader.idh_config.point_in_time_restore_allowed ? module.idh_loader.idh_config.point_in_time_retention_days + 1 : null
  blob_container_delete_retention_days = module.idh_loader.idh_config.point_in_time_retention_days

  blob_storage_policy = {
    enable_immutability_policy = var.immutability_policy.enabled
    blob_restore_policy_days   = module.idh_loader.idh_config.point_in_time_retention_days
  }

  private_endpoint_enabled         = module.idh_loader.idh_config.private_endpoint_enabled
  access_tier                      = module.idh_loader.idh_config.access_tier
  blob_last_access_time_enabled    = module.idh_loader.idh_config.blob_last_access_time_enabled
  cross_tenant_replication_enabled = module.idh_loader.idh_config.cross_tenant_replication_enabled
  is_hns_enabled                   = module.idh_loader.idh_config.is_hns_enabled
  min_tls_version                  = module.idh_loader.idh_config.min_tls_version

  private_dns_zone_table_ids  = var.private_dns_zone_table_ids
  private_dns_zone_queue_ids  = var.private_dns_zone_queue_ids
  private_dns_zone_blob_ids   = var.private_dns_zone_blob_ids
  private_dns_zone_dfs_ids    = var.private_dns_zone_dfs_ids
  private_dns_zone_file_ids   = var.private_dns_zone_file_ids
  private_dns_zone_web_ids    = var.private_dns_zone_web_ids
  action                      = var.action
  custom_domain               = var.custom_domain
  domain                      = var.domain
  enable_identity             = var.enable_identity
  use_legacy_defender_version = false
  error_404_document          = var.error_404_document
  index_document              = var.index_document
  immutability_policy_props = {
    allow_protected_append_writes = var.immutability_policy.allow_protected_append_writes
    period_since_creation_in_days = var.immutability_policy.period_since_creation_in_days
  }
  is_sftp_enabled            = var.is_sftp_enabled
  low_availability_threshold = var.low_availability_threshold
  network_rules              = var.network_rules
  subnet_id                  = var.private_endpoint_subnet_id
}
