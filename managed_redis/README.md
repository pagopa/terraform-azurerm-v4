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

  sku_name                  = "Enterprise_E5"
  high_availability_enabled = false
  public_network_access     = "Disabled"
  minimum_tls_version       = "1.2"
}
```

### EnterpriseFlash with Modules and Private Endpoint

```hcl
module "managed_redis_advanced" {
  source = "./managed_redis"

  name                = "myredis-flash"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  # EnterpriseFlash tier
  sku_name                  = "EnterpriseFlash_F300"
  high_availability_enabled = true
  public_network_access     = "Disabled"
  minimum_tls_version       = "1.3"

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

  sku_name                  = "Enterprise_E20"
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
- `sku_name` - The SKU tier (Enterprise_E5, Enterprise_E10, Enterprise_E20, Enterprise_E50, Enterprise_E100, EnterpriseFlash_F300, EnterpriseFlash_F700, EnterpriseFlash_F1500)

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

| Tier | Memory | Use Case | HA | Persistence |
|------|--------|----------|----|----|
| Enterprise_E5 | 5GB | Development | Optional | Optional |
| Enterprise_E10 | 10GB | Small Production | Optional | Optional |
| Enterprise_E20 | 20GB | Medium Production | Optional | Optional |
| Enterprise_E50 | 50GB | Large Production | Optional | Optional |
| Enterprise_E100 | 100GB | Extra Large Production | Optional | Optional |
| EnterpriseFlash_F300 | 300GB | Flash (NVMe) Workloads | Optional | Optional |
| EnterpriseFlash_F700 | 700GB | High-Performance Flash | Optional | Optional |
| EnterpriseFlash_F1500 | 1500GB | Ultra High-Performance | Optional | Optional |

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
<!-- END_TF_DOCS -->
