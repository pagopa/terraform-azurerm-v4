# Managed Redis Module

This module creates and manages Azure Database for Redis Enterprise instances with optional private endpoints, comprehensive monitoring alerts, and advanced configuration options.

## Overview

The `managed_redis` module provides a production-ready wrapper around the `azurerm_managed_redis` Azure provider resource. It enables deployment of Azure Database for Redis Enterprise clusters with enterprise features like persistence, modules support, customer-managed keys, and comprehensive monitoring.

## Features

- **Enterprise SKUs**: Support for all Enterprise (E5-E100) and EnterpriseFlash (F300-F1500) tiers
- **High Availability**: Optional high availability across availability zones
- **Private Endpoints**: Optional private endpoint deployment with DNS integration
- **Persistence**: Configurable RDB and AOF persistence options
- **Redis Modules**: Support for RediSearch, RedisJSON, RedisBloom, RedisTimeSeries, RedisAI, RedisGears
- **Customer-Managed Keys**: Optional encryption with customer-managed keys
- **Comprehensive Monitoring**: 4 pre-built alert types with for_each pattern
- **Advanced Database Configuration**: RESP3 protocol, clustering policies, eviction policies
- **Security-First Design**: TLS 1.2+ enforced, authentication enabled, public access disabled by default

## Examples

### Basic Enterprise Deployment

```hcl
module "managed_redis" {
  source = "./managed_redis"

  name                = "myredis"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  sku_name                  = "MemoryOptimized_M10"
  high_availability_enabled = false
  public_network_access     = "Disabled"
}
```

### Flash-Optimized with Modules and Private Endpoint

```hcl
module "managed_redis_advanced" {
  source = "./managed_redis"

  name                = "myredis-flash"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  # Flash-optimized tier
  sku_name                  = "FlashOptimized_A1000"
  high_availability_enabled = true
  public_network_access     = "Disabled"

  # Database configuration
  client_protocol   = "RESP3"
  clustering_policy = "EnterpriseCluster"
  eviction_policy   = "allkeys-lru"

  # Persistence
  persistence_configuration = {
    aof_enabled = true
    rdb_enabled = false
  }

  # Modules
  modules = [
    { name = "RediSearch" },
    { name = "RedisJSON" },
    { name = "RedisBloom" }
  ]

  # Private endpoint
  private_endpoint_enabled   = true
  private_endpoint_subnet_id = azurerm_subnet.private_endpoints.id
  private_dns_zone_ids       = [azurerm_private_dns_zone.redis.id]

  # Alerting
  alert_action_group_ids           = [azurerm_monitor_action_group.ops.id]
  enable_cpu_alerts                = true
  enable_memory_alerts             = true
  enable_eviction_alerts           = true
  enable_connection_alerts         = true

  tags = {
    Environment = "production"
  }
}
```

### With Customer-Managed Key Encryption

```hcl
module "managed_redis_encrypted" {
  source = "./managed_redis"

  name                = "myredis-secure"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  sku_name                  = "MemoryOptimized_M100"
  high_availability_enabled = true

  customer_managed_key_config = {
    key_vault_key_id           = azurerm_key_vault_key.redis.id
    user_assigned_identity_id  = azurerm_user_assigned_identity.redis.id
  }

  tags = {
    Environment = "production"
  }
}
```

## Input Variables

### Required Variables

- `name` - The name of the managed Redis instance (1-63 characters)
- `location` - The Azure region for deployment
- `resource_group_name` - The resource group name for the instance
- `sku_name` - The SKU tier. Valid values: Balanced_B*, ComputeOptimized_X*, FlashOptimized_A*, MemoryOptimized_M* (see Azure docs for specific sizes)

### High Availability & Network

- `high_availability_enabled` - Enable HA across zones (default: true)
- `public_network_access` - Public access setting: "Enabled" or "Disabled" (default: "Disabled")
- `subnet_id` - Subnet ID for the instance (optional)

### Security

- `minimum_tls_version` - Minimum TLS version: 1.0, 1.1, 1.2, 1.3 (default: 1.2)
- `access_keys_authentication_enabled` - Enable access key auth (default: true)
- `customer_managed_key_config` - Customer-managed key encryption config (optional)

### Database Configuration

- `client_protocol` - Client protocol: RESP2 or RESP3 (default: RESP3)
- `clustering_policy` - Clustering: EnterpriseCluster or OSSCluster (default: EnterpriseCluster)
- `eviction_policy` - Eviction policy (default: allkeys-lru)
  - Options: allkeys-lfu, allkeys-lru, allkeys-random, volatile-lfu, volatile-lru, volatile-random, volatile-ttl, noeviction
- `maxmemory_policy` - Maxmemory policy (default: allkeys-lru)

### Persistence & Modules

- `persistence_configuration` - RDB and AOF settings
  ```hcl
  persistence_configuration = {
    aof_enabled = true
    rdb_enabled = false
  }
  ```

- `modules` - List of modules to load
  ```hcl
  modules = [
    { name = "RediSearch" },
    { name = "RedisJSON" }
  ]
  ```

### Private Endpoint

- `private_endpoint_enabled` - Enable private endpoint (default: false)
- `private_endpoint_subnet_id` - Subnet for private endpoint (required if enabled)
- `private_dns_zone_ids` - Private DNS zone IDs (optional)

### Monitoring & Alerts

- `alert_action_group_ids` - Action group IDs for alerts (required for alerts to work)
- `enable_cpu_alerts` - Alert on high CPU (default: false)
- `cpu_usage_percentage_threshold` - CPU alert threshold (default: 80)
- `enable_memory_alerts` - Alert on high memory (default: false)
- `memory_usage_percentage_threshold` - Memory alert threshold (default: 80)
- `enable_eviction_alerts` - Alert on eviction events (default: false)
- `enable_connection_alerts` - Alert on high connections (default: false)
- `connection_count_threshold` - Connection threshold (default: 5000)

### Tags & Labels

- `tags` - Azure resource tags (default: {})

## Outputs

- `id` - The resource ID of the managed Redis instance
- `name` - The name of the instance
- `location` - The Azure region
- `resource_group_name` - The resource group name
- `hostname` - The connection hostname
- `sku_name` - The SKU tier
- `high_availability_enabled` - Whether HA is enabled
- `public_network_access` - Public access setting
- `private_endpoint_id` - The private endpoint ID (if enabled)
- `private_endpoint_network_interface_ids` - Private endpoint IP addresses

## Notes

### SKU Selection Guide

| Tier | Memory | Use Case | HA | Notes |
|------|--------|----------|----|----|
| Balanced_B3-B1000 | 3GB-1000GB | General-purpose, cost-optimized | Optional | Balanced compute and memory |
| ComputeOptimized_X3-X700 | 3GB-70GB | High throughput, compute-intensive | Optional | CPU-optimized performance |
| FlashOptimized_A250-A4500 | 250GB-4500GB | Ultra-high throughput, NVMe-backed | Optional | Maximum performance |
| MemoryOptimized_M10-M2000 | 10GB-2000GB | Large datasets, memory-intensive | Optional | Memory-optimized for big data |

### Security Best Practices

1. **Network Access**: Public access is disabled by default. Use private endpoints for production.
2. **TLS Enforcement**: Minimum TLS 1.2 by default, upgrade to 1.3 for maximum security.
3. **Authentication**: Access key authentication enabled by default.
4. **Encryption**: Consider customer-managed keys for compliance requirements.

### Alert Configuration

- All alerts use `for_each` with `alert_action_group_ids` for scalability
- Alerts are only created if action group IDs are provided
- Default thresholds are production-reasonable but tunable
- Severity: 0=Critical, 1=Error, 2=Warning, 3=Informational

### Limitations

1. Subnet ID not supported for Enterprise tier (only for clusters)
2. Only one customer-managed key configuration per instance
3. Modules must be compatible with selected SKU
4. Persistence may impact performance on high-throughput workloads

### Provider Version

- Terraform >= 1.9.0
- Azure Provider ~> 4

## Examples

Test configurations are provided in `tests/`:

- `tests/basic.tf` - Basic Enterprise_E5 deployment
- `tests/premium_with_alerts.tf` - EnterpriseFlash with modules and alerts

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 4 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_managed_redis.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/managed_redis) | resource |
| [azurerm_monitor_metric_alert.connection_count](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_metric_alert) | resource |
| [azurerm_monitor_metric_alert.cpu_usage](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_metric_alert) | resource |
| [azurerm_monitor_metric_alert.eviction_events](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_metric_alert) | resource |
| [azurerm_monitor_metric_alert.memory_usage](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_metric_alert) | resource |
| [azurerm_private_endpoint.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_endpoint) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_access_keys_authentication_enabled"></a> [access\_keys\_authentication\_enabled](#input\_access\_keys\_authentication\_enabled) | Enable access keys authentication for the default database. | `bool` | `true` | no |
| <a name="input_alert_action_group_ids"></a> [alert\_action\_group\_ids](#input\_alert\_action\_group\_ids) | List of Azure Monitor action group IDs for alerts. | `list(string)` | `[]` | no |
| <a name="input_client_protocol"></a> [client\_protocol](#input\_client\_protocol) | Client protocol version (Encrypted or Plaintext). | `string` | `"Encrypted"` | no |
| <a name="input_clustering_policy"></a> [clustering\_policy](#input\_clustering\_policy) | Clustering policy (EnterpriseCluster or OSSCluster). | `string` | `"EnterpriseCluster"` | no |
| <a name="input_connection_count_threshold"></a> [connection\_count\_threshold](#input\_connection\_count\_threshold) | Threshold for connection count alert. | `number` | `5000` | no |
| <a name="input_cpu_usage_percentage_threshold"></a> [cpu\_usage\_percentage\_threshold](#input\_cpu\_usage\_percentage\_threshold) | Threshold percentage for CPU usage alert. | `number` | `80` | no |
| <a name="input_customer_managed_key_config"></a> [customer\_managed\_key\_config](#input\_customer\_managed\_key\_config) | Customer managed key configuration for encryption. | <pre>object({<br/>    key_vault_key_id          = string<br/>    user_assigned_identity_id = string<br/>  })</pre> | `null` | no |
| <a name="input_enable_connection_alerts"></a> [enable\_connection\_alerts](#input\_enable\_connection\_alerts) | Enable alerts for high connection count. | `bool` | `false` | no |
| <a name="input_enable_cpu_alerts"></a> [enable\_cpu\_alerts](#input\_enable\_cpu\_alerts) | Enable alerts for high CPU usage. | `bool` | `false` | no |
| <a name="input_enable_eviction_alerts"></a> [enable\_eviction\_alerts](#input\_enable\_eviction\_alerts) | Enable alerts for eviction events. | `bool` | `false` | no |
| <a name="input_enable_memory_alerts"></a> [enable\_memory\_alerts](#input\_enable\_memory\_alerts) | Enable alerts for high memory usage. | `bool` | `false` | no |
| <a name="input_eviction_policy"></a> [eviction\_policy](#input\_eviction\_policy) | Eviction policy (AllKeysLFU, AllKeysLRU, AllKeysRandom, VolatileLFU, VolatileLRU, VolatileRandom, VolatileTTL, NoEviction). | `string` | `"AllKeysLRU"` | no |
| <a name="input_high_availability_enabled"></a> [high\_availability\_enabled](#input\_high\_availability\_enabled) | Enable high availability for the managed Redis instance. | `bool` | `true` | no |
| <a name="input_location"></a> [location](#input\_location) | The Azure location where the managed Redis instance will be created. | `string` | n/a | yes |
| <a name="input_memory_usage_percentage_threshold"></a> [memory\_usage\_percentage\_threshold](#input\_memory\_usage\_percentage\_threshold) | Threshold percentage for memory usage alert. | `number` | `80` | no |
| <a name="input_modules"></a> [modules](#input\_modules) | List of modules to load (RediSearch, RedisJSON, RedisBloom, RedisTimeSeries, RedisAI, RedisGears). | <pre>list(object({<br/>    name = string<br/>  }))</pre> | `[]` | no |
| <a name="input_name"></a> [name](#input\_name) | The name of the managed Redis instance. | `string` | n/a | yes |
| <a name="input_persistence_configuration"></a> [persistence\_configuration](#input\_persistence\_configuration) | Persistence configuration for RDB and AOF. | <pre>object({<br/>    aof_enabled = bool<br/>    rdb_enabled = bool<br/>  })</pre> | <pre>{<br/>  "aof_enabled": false,<br/>  "rdb_enabled": false<br/>}</pre> | no |
| <a name="input_private_dns_zone_ids"></a> [private\_dns\_zone\_ids](#input\_private\_dns\_zone\_ids) | The list of private DNS zone IDs for the private endpoint. | `list(string)` | `[]` | no |
| <a name="input_private_endpoint_enabled"></a> [private\_endpoint\_enabled](#input\_private\_endpoint\_enabled) | Enable private endpoint for the managed Redis instance. | `bool` | `false` | no |
| <a name="input_private_endpoint_subnet_id"></a> [private\_endpoint\_subnet\_id](#input\_private\_endpoint\_subnet\_id) | The subnet ID for the private endpoint (required if private\_endpoint\_enabled is true). | `string` | `null` | no |
| <a name="input_public_network_access"></a> [public\_network\_access](#input\_public\_network\_access) | Public network access setting (Enabled or Disabled). | `string` | `"Disabled"` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | The name of the resource group where the managed Redis instance will be created. | `string` | n/a | yes |
| <a name="input_sku_name"></a> [sku\_name](#input\_sku\_name) | The SKU name for the managed Redis instance. Valid values: Balanced\_B{0\|1\|3\|5\|10\|20\|50\|100\|150\|250\|350\|500\|700\|1000}, ComputeOptimized\_X{3\|5\|10\|20\|50\|100\|150\|250\|350\|500\|700}, FlashOptimized\_A{250\|500\|700\|1000\|1500\|2000\|4500}, MemoryOptimized\_M{10\|20\|50\|100\|150\|250\|350\|500\|1000\|1500\|2000}. | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to the managed Redis instance and related resources. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_high_availability_enabled"></a> [high\_availability\_enabled](#output\_high\_availability\_enabled) | Whether high availability is enabled. |
| <a name="output_hostname"></a> [hostname](#output\_hostname) | The hostname of the managed Redis instance. |
| <a name="output_id"></a> [id](#output\_id) | The ID of the managed Redis instance. |
| <a name="output_location"></a> [location](#output\_location) | The Azure location of the managed Redis instance. |
| <a name="output_name"></a> [name](#output\_name) | The name of the managed Redis instance. |
| <a name="output_private_endpoint_id"></a> [private\_endpoint\_id](#output\_private\_endpoint\_id) | The ID of the private endpoint (if enabled). |
| <a name="output_private_endpoint_network_interface_ids"></a> [private\_endpoint\_network\_interface\_ids](#output\_private\_endpoint\_network\_interface\_ids) | The IP addresses assigned to the private endpoint. |
| <a name="output_public_network_access"></a> [public\_network\_access](#output\_public\_network\_access) | The public network access setting. |
| <a name="output_resource_group_name"></a> [resource\_group\_name](#output\_resource\_group\_name) | The resource group name of the managed Redis instance. |
| <a name="output_sku_name"></a> [sku\_name](#output\_sku\_name) | The SKU name of the managed Redis instance. |
<!-- END_TF_DOCS -->
