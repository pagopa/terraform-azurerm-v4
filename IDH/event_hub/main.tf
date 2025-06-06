module "idh_loader" {
  source = "../00_idh_loader"

  prefix       = var.prefix
  env          = var.env
  idh_resource = var.idh_resource
  idh_category = "event_hub"
}

resource "terraform_data" "validation" {
  input = timestamp()

  lifecycle {
    precondition {
      condition     = !module.idh_loader.idh_config.auto_inflate_enabled ? lookup(module.idh_loader.idh_config, "maximum_throughput_units", null) == null : true
      error_message = "maximum_throughput_units must not be defined when auto_inflate_enabled is true"
    }

  }
}

module "event_hub" {
  source = "../../eventhub"

  depends_on = [terraform_data.validation]

  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location

  capacity                      = module.idh_loader.idh_config.capacity
  auto_inflate_enabled          = module.idh_loader.idh_config.auto_inflate_enabled
  maximum_throughput_units      = module.idh_loader.idh_config.auto_inflate_enabled ? module.idh_loader.idh_config.maximum_throughput_units : null
  sku                           = module.idh_loader.idh_config.sku
  private_endpoint_created      = module.idh_loader.idh_config.private_endpoint_enabled
  public_network_access_enabled = module.idh_loader.idh_config.public_network_access_enabled
  metric_alerts_create          = module.idh_loader.idh_config.create_metric_alerts
  minimum_tls_version           = module.idh_loader.idh_config.minimum_tls_version
  alerts_enabled                = module.idh_loader.idh_config.alerts_enabled

  network_rulesets                     = var.network_rulesets
  private_endpoint_resource_group_name = var.private_endpoint_resource_group_name
  private_dns_zones_ids                = var.private_dns_zones_ids
  private_endpoint_subnet_id           = var.private_endpoint_subnet_id
  metric_alerts                        = var.metric_alerts
  action                               = var.action

  eventhubs = []

  tags = var.tags
}

