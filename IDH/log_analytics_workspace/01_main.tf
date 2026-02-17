module "idh_loader" {
  source = "../01_idh_loader"

  product_name      = var.product_name
  env               = var.env
  idh_resource_tier = var.idh_resource_tier
  idh_resource_type = "log_analytics_workspace"
}

# IDH/subnet
module "private_endpoint_snet" {
  count             = var.embedded_subnet.enabled ? 1 : 0
  source            = "../subnet"
  env               = var.env
  idh_resource_tier = "slash28_privatelink_true"
  product_name      = var.product_name

  name                 = "${var.name}-pe-snet"
  resource_group_name  = var.embedded_subnet.vnet_rg_name
  virtual_network_name = var.embedded_subnet.vnet_name

  ## NSG Rules embedded
  create_self_inbound_nsg_rule = module.idh_loader.idh_resource_configuration.create_self_inbound_nsg_rule
  embedded_nsg_configuration   = var.embedded_nsg_configuration
  nsg_flow_log_configuration = {
    traffic_analytics_law_name = module.log_analytics_workspace.name
    traffic_analytics_law_rg   = module.log_analytics_workspace.resource_group
    enabled                    = var.nsg_flow_log_configuration.enabled
    network_watcher_name       = var.nsg_flow_log_configuration.network_watcher_name
    storage_account_id         = var.nsg_flow_log_configuration.storage_account_id
  }

  tags = var.tags
}

module "log_analytics_workspace" {
  source = "../../log_analytics_workspace"

  ## Basic vars
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location

  ## LAW Properties
  law_sku                        = module.idh_loader.idh_resource_configuration.law_sku
  law_daily_quota_gb             = module.idh_loader.idh_resource_configuration.law_daily_quota_gb
  law_retention_in_days          = module.idh_loader.idh_resource_configuration.law_retention_in_days
  law_internet_ingestion_enabled = module.idh_loader.idh_resource_configuration.law_internet_ingestion_enabled
  law_internet_query_enabled     = module.idh_loader.idh_resource_configuration.law_internet_query_enabled

  ## APP Insight properties
  create_application_insights              = var.create_application_insights
  application_insights_id                  = var.application_insights_id
  application_insights_name                = var.application_insights_name
  application_insights_resource_group_name = var.application_insights_resource_group_name

  application_insights_application_type                      = module.idh_loader.idh_resource_configuration.application_insights_application_type
  application_insights_daily_data_cap_in_gb                  = module.idh_loader.idh_resource_configuration.application_insights_daily_data_cap_in_gb
  application_insights_daily_data_cap_notifications_disabled = module.idh_loader.idh_resource_configuration.application_insights_daily_data_cap_notifications_disabled
  application_insights_disable_ip_masking                    = module.idh_loader.idh_resource_configuration.application_insights_disable_ip_masking
  application_insights_local_authentication_disabled         = module.idh_loader.idh_resource_configuration.application_insights_local_authentication_disabled

  ## Private Endpoint
  private_endpoint_enabled = module.idh_loader.idh_resource_configuration.private_endpoint_enabled
  subnet_id                = var.embedded_subnet.enabled ? module.private_endpoint_snet[0].subnet_id : null
  private_dns_zone_ids     = var.private_dns_zone_ids

  ## Created by users
  log_analytics_workspace_tables = var.log_analytics_workspace_tables

  ## Module tags
  tags = var.tags
}