module "idh_loader" {
  source = "../01_idh_loader"

  product_name      = var.product_name
  env               = var.env
  idh_resource_tier = var.idh_resource_tier
  idh_resource_type = "event_hub"
}

resource "terraform_data" "validation" {
  input = timestamp()

  lifecycle {
    precondition {
      condition     = !module.idh_loader.idh_resource_configuration.auto_inflate_enabled ? lookup(module.idh_loader.idh_resource_configuration, "maximum_throughput_units", null) == null : true
      error_message = "maximum_throughput_units must not be defined when auto_inflate_enabled is true"
    }

  }
}

# -------------------------------------------------------------------
# Event Hub
# -------------------------------------------------------------------
module "event_hub" {
  source = "../../eventhub"

  depends_on = [terraform_data.validation]

  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location

  capacity                      = module.idh_loader.idh_resource_configuration.capacity
  auto_inflate_enabled          = module.idh_loader.idh_resource_configuration.auto_inflate_enabled
  maximum_throughput_units      = module.idh_loader.idh_resource_configuration.auto_inflate_enabled ? module.idh_loader.idh_resource_configuration.maximum_throughput_units : null
  sku                           = module.idh_loader.idh_resource_configuration.sku
  private_endpoint_created      = module.idh_loader.idh_resource_configuration.private_endpoint_enabled
  public_network_access_enabled = module.idh_loader.idh_resource_configuration.public_network_access_enabled
  metric_alerts_create          = module.idh_loader.idh_resource_configuration.create_metric_alerts
  minimum_tls_version           = module.idh_loader.idh_resource_configuration.minimum_tls_version
  alerts_enabled                = module.idh_loader.idh_resource_configuration.alerts_enabled

  network_rulesets                     = var.network_rulesets
  private_endpoint_resource_group_name = var.private_endpoint_resource_group_name
  private_dns_zones_ids                = var.private_dns_zones_ids
  private_endpoint_subnet_id           = var.private_endpoint_subnet_id
  metric_alerts                        = var.metric_alerts
  action                               = var.action

  eventhubs = []

  tags = var.tags
}

