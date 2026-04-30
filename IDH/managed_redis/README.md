# Managed Redis (Enterprise)

This module creates and manages Azure Database for Redis Enterprise instances with optional private endpoints, comprehensive monitoring alerts, modules support, and advanced configuration options.

## IDH resources available

[Here's](./LIBRARY.md) the list of `idh_resource_tier` available for this module

## How to use it

```hcl
module "managed_redis" {
  source = "./.terraform/modules/__v4__/IDH/managed_redis"

  product_name      = "pagopa"
  env                = "prod"
  idh_resource_tier  = "balanced_3gb"

  name                = "myredis"
  location            = var.location
  resource_group_name = azurerm_resource_group.example.name
  tags                = var.tags

  # Optional: custom alert action groups
  alert_action_group_ids = [azurerm_monitor_action_group.ops.id]

  # Optional: embedded subnet for private endpoint
  embedded_subnet = {
    enabled              = true
    vnet_name            = azurerm_virtual_network.core.name
    vnet_rg_name         = azurerm_resource_group.network.name
    private_dns_zone_ids = [azurerm_private_dns_zone.redis.id]
  }
}
```

## Examples

### Basic Development Tier (0.5GB Balanced)

```hcl
module "managed_redis_dev" {
  source = "./.terraform/modules/__v4__/IDH/managed_redis"

  product_name      = "pagopa"
  env                = "dev"
  idh_resource_tier  = "balanced_0_5gb"

  name                = "redis-dev"
  location            = "westeurope"
  resource_group_name = azurerm_resource_group.dev.name
  tags = {
    Environment = "development"
  }
}
```

### Production with Private Endpoint and Full Monitoring (3GB-6GB Balanced)

```hcl
module "managed_redis_prod" {
  source = "./.terraform/modules/__v4__/IDH/managed_redis"

  product_name      = "pagopa"
  env                = "prod"
  idh_resource_tier  = "balanced_6gb"

  name                = "redis-prod"
  location            = "westeurope"
  resource_group_name = azurerm_resource_group.prod.name

  # Optional override if needed
  sku_name_override = "Balanced_B5" # optional

  # Private endpoint configuration
  embedded_subnet = {
    enabled              = true
    vnet_name            = azurerm_virtual_network.prod_vnet.name
    vnet_rg_name         = azurerm_resource_group.network.name
    private_dns_zone_ids = [azurerm_private_dns_zone.redis.id]
  }

  # Monitoring
  alert_action_group_ids = [
    azurerm_monitor_action_group.critical.id,
    azurerm_monitor_action_group.warning.id
  ]

  tags = {
    Environment = "production"
    CostCenter  = "engineering"
  }
}
```

### With Customer-Managed Key Encryption

```hcl
module "managed_redis_encrypted" {
  source = "./.terraform/modules/__v4__/IDH/managed_redis"

  product_name      = "pagopa"
  env                = "prod"
  idh_resource_tier  = "memory_optimized_m100"

  name                = "redis-secure"
  location            = "westeurope"
  resource_group_name = azurerm_resource_group.prod.name

  # Customer-managed encryption
  customer_managed_key_config = {
    key_vault_key_id          = azurerm_key_vault_key.redis.id
    user_assigned_identity_id = azurerm_user_assigned_identity.redis.id
  }

  tags = {
    Environment = "production"
    Compliance  = "required"
  }
}
```

## Notes

### Tier Selection

This module supports balanced, compute-optimized, flash-optimized, and memory-optimized tiers:

- **Balanced (B*)**: General-purpose Redis with balanced compute and memory (B3-B1000)
- **ComputeOptimized (X*)**: High-performance compute-focused Redis (X3-X700)
- **FlashOptimized (A*)**: High-performance NVMe-backed Redis for extreme throughput (A250-A4500)
- **MemoryOptimized (M*)**: High-memory Redis for large datasets (M10-M2000)

### Network Security

- Public network access is disabled by default (set via tier configuration)
- Private endpoint is strongly recommended for production deployments
- NSG flow logs can be enabled for traffic analysis and compliance

### Monitoring and Alerts

Alerts are created only if:
1. The tier configuration enables the specific alert type
2. `alert_action_group_ids` is provided

Default thresholds are production-reasonable but can be tuned via tier configuration:
- CPU alert: 80% (default)
- Memory alert: 80% (default)
- Eviction events: threshold 0 (any eviction)
- Connection count: 5000 (default)

### Limitations

- Customer-managed keys require a user-assigned identity with Key Vault permissions
- Modules must be compatible with the selected SKU
- Private endpoint requires a separate subnet (or embedded subnet creation)
- High availability changes require resource recreation

## Troubleshooting

### Private Endpoint Subnet Issues

If you see subnet conflicts:
- Ensure subnet size is at least `/28` for private endpoints
- Verify subnet is not delegated to other services
- Check NSG rules allow required outbound traffic

### Alert Failures

Alerts won't be created if:
- No action group IDs are provided
- Action group IDs are invalid
- Metrics namespace doesn't match provider version

### Module Load Failures

Some modules may not be available for all SKUs:
- Verify module compatibility with selected tier in Azure documentation
- EnterpriseFlash supports all modules; Enterprise tiers have restrictions per version

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 4 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_idh_loader"></a> [idh\_loader](#module\_idh\_loader) | ../01_idh_loader | n/a |
| <a name="module_managed_redis"></a> [managed\_redis](#module\_managed\_redis) | ../../managed_redis | n/a |
| <a name="module_managed_redis_replica"></a> [managed\_redis\_replica](#module\_managed\_redis\_replica) | ../../managed_redis | n/a |
| <a name="module_private_endpoint_replica_snet"></a> [private\_endpoint\_replica\_snet](#module\_private\_endpoint\_replica\_snet) | ../subnet | n/a |
| <a name="module_private_endpoint_snet"></a> [private\_endpoint\_snet](#module\_private\_endpoint\_snet) | ../subnet | n/a |

## Resources

| Name | Type |
|------|------|
| [azurerm_managed_redis_geo_replication.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/managed_redis_geo_replication) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_alert_action_group_ids"></a> [alert\_action\_group\_ids](#input\_alert\_action\_group\_ids) | (Optional) List of Azure Monitor action group IDs for alerts. | `list(string)` | `[]` | no |
| <a name="input_customer_managed_key_config"></a> [customer\_managed\_key\_config](#input\_customer\_managed\_key\_config) | (Optional) Customer managed key configuration for encryption at rest. | <pre>object({<br/>    key_vault_key_id          = string<br/>    user_assigned_identity_id = string<br/>  })</pre> | `null` | no |
| <a name="input_embedded_nsg_configuration"></a> [embedded\_nsg\_configuration](#input\_embedded\_nsg\_configuration) | (Optional) List of allowed CIDR and name for NSG rules. | <pre>object({<br/>    source_address_prefixes      = list(string)<br/>    source_address_prefixes_name = string<br/>  })</pre> | <pre>{<br/>  "source_address_prefixes": [<br/>    "*"<br/>  ],<br/>  "source_address_prefixes_name": "All"<br/>}</pre> | no |
| <a name="input_embedded_subnet"></a> [embedded\_subnet](#input\_embedded\_subnet) | (Optional) Configuration for creating an embedded Subnet for the managed Redis private endpoint. When enabled, 'private\_endpoint\_subnet\_id' must be null. | <pre>object({<br/>    enabled              = bool<br/>    vnet_name            = optional(string, null)<br/>    vnet_rg_name         = optional(string, null)<br/>    private_dns_zone_ids = optional(list(string), [])<br/>  })</pre> | <pre>{<br/>  "enabled": false,<br/>  "private_dns_zone_ids": [],<br/>  "vnet_name": null,<br/>  "vnet_rg_name": null<br/>}</pre> | no |
| <a name="input_env"></a> [env](#input\_env) | (Required) Environment for which the resource will be created | `string` | n/a | yes |
| <a name="input_eviction_policy_override"></a> [eviction\_policy\_override](#input\_eviction\_policy\_override) | (Optional) Override the eviction policy from tier configuration. Valid values: AllKeysLFU, AllKeysLRU, AllKeysRandom, VolatileLFU, VolatileLRU, VolatileRandom, VolatileTTL, NoEviction | `string` | `null` | no |
| <a name="input_geo_replication"></a> [geo\_replication](#input\_geo\_replication) | (Optional) Map of geo replication settings | <pre>object({<br/>    enabled      = bool<br/>    subnet_id    = optional(string, null)<br/>    location     = optional(string, null)<br/>    vnet_rg_name = optional(string, null)<br/>    vnet_name    = optional(string, null)<br/>  })</pre> | <pre>{<br/>  "enabled": false,<br/>  "location": null,<br/>  "subnet_id": null,<br/>  "vnet_name": null,<br/>  "vnet_rg_name": null<br/>}</pre> | no |
| <a name="input_idh_resource_tier"></a> [idh\_resource\_tier](#input\_idh\_resource\_tier) | (Required) The name of IDH resource tier to be created. See LIBRARY.md for available tiers. | `string` | n/a | yes |
| <a name="input_location"></a> [location](#input\_location) | (Required) The Azure location where the managed Redis instance will be created. | `string` | n/a | yes |
| <a name="input_modules_override"></a> [modules\_override](#input\_modules\_override) | (Optional) Override the modules list from tier configuration. Useful to add/modify modules like RediSearch, RedisJSON, etc. | <pre>list(object({<br/>    name = string<br/>  }))</pre> | `null` | no |
| <a name="input_name"></a> [name](#input\_name) | (Required) The name of the managed Redis instance. | `string` | n/a | yes |
| <a name="input_nsg_flow_log_configuration"></a> [nsg\_flow\_log\_configuration](#input\_nsg\_flow\_log\_configuration) | (Optional) NSG flow log configuration | <pre>object({<br/>    enabled                    = bool<br/>    network_watcher_name       = optional(string, null)<br/>    network_watcher_rg         = optional(string, null)<br/>    storage_account_id         = optional(string, null)<br/>    traffic_analytics_law_name = optional(string, null)<br/>    traffic_analytics_law_rg   = optional(string, null)<br/>  })</pre> | <pre>{<br/>  "enabled": false<br/>}</pre> | no |
| <a name="input_private_dns_zone_ids"></a> [private\_dns\_zone\_ids](#input\_private\_dns\_zone\_ids) | (Optional) The list of private DNS zone IDs for the private endpoint. | `list(string)` | `[]` | no |
| <a name="input_private_endpoint_subnet_id"></a> [private\_endpoint\_subnet\_id](#input\_private\_endpoint\_subnet\_id) | (Optional) The subnet ID for the private endpoint. Required if private endpoint is enabled and embedded\_subnet is not used. | `string` | `null` | no |
| <a name="input_product_name"></a> [product\_name](#input\_product\_name) | (Required) product\_name used to identify the platform for which the resource will be created | `string` | n/a | yes |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | (Required) The name of the resource group where the managed Redis instance will be created. | `string` | n/a | yes |
| <a name="input_resource_group_nsg_name"></a> [resource\_group\_nsg\_name](#input\_resource\_group\_nsg\_name) | (Optional) The name of the nsg Resource Group. | `string` | `""` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | (Required) Tags to apply to the managed Redis instance and related resources. | `map(string)` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_high_availability_enabled"></a> [high\_availability\_enabled](#output\_high\_availability\_enabled) | Whether high availability is enabled. |
| <a name="output_hostname"></a> [hostname](#output\_hostname) | The hostname of the managed Redis instance. |
| <a name="output_id"></a> [id](#output\_id) | The resource ID of the managed Redis instance. |
| <a name="output_location"></a> [location](#output\_location) | The Azure location of the managed Redis instance. |
| <a name="output_name"></a> [name](#output\_name) | The name of the managed Redis instance. |
| <a name="output_port"></a> [port](#output\_port) | n/a |
| <a name="output_primary_access_key"></a> [primary\_access\_key](#output\_primary\_access\_key) | n/a |
| <a name="output_primary_connection_url"></a> [primary\_connection\_url](#output\_primary\_connection\_url) | The primary connection URL for the managed Redis instance. |
| <a name="output_private_endpoint_id"></a> [private\_endpoint\_id](#output\_private\_endpoint\_id) | The ID of the private endpoint (if enabled). |
| <a name="output_resource_group_name"></a> [resource\_group\_name](#output\_resource\_group\_name) | The resource group name of the managed Redis instance. |
| <a name="output_secondary_access_key"></a> [secondary\_access\_key](#output\_secondary\_access\_key) | n/a |
<!-- END_TF_DOCS -->

