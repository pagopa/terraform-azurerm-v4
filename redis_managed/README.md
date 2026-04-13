# Azure Redis Cache Module

This module provides a Terraform implementation for Azure Redis Cache, offering high-performance, managed in-memory data store with enterprise-grade features, HA capabilities, private endpoint support, and comprehensive alerting.

## Usage

### Basic Example

```hcl
module "redis" {
  source = "./redis_managed"

  name                = "myredis"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  sku_name            = "Standard"
  family              = "C"
  capacity            = 2

  minimum_tls_version = "1.2"

  tags = {
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}
```

### With Private Endpoint and Alerting

```hcl
module "redis_secure" {
  source = "./redis_managed"

  name                = "secure-redis"
  resource_group_name = azurerm_resource_group.prod.name
  location            = azurerm_resource_group.prod.location
  sku_name            = "Premium"
  family              = "P"
  capacity            = 3

  minimum_tls_version = "1.2"
  lock_enabled        = true

  # Private endpoint for VNet-only connectivity
  private_endpoint_enabled   = true
  private_endpoint_subnet_id = azurerm_subnet.pe.id

  # Alert configuration
  action_group_enabled = true
  alert_email_receivers = [
    "devops-team@company.com",
    "on-call@company.com"
  ]
  alert_high_cpu_threshold             = 70
  alert_high_memory_threshold          = 75
  alert_eviction_threshold             = 100
  alert_connection_failures_threshold  = 10

  tags = {
    Environment = "production"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.10.1 |
| azurerm | >= 4.0 |

## Arguments

### Required

| Name | Description | Type |
|------|-------------|------|
| name | The name of the Redis cache instance. | `string` |
| resource_group_name | The name of the resource group in which to create the Redis cache. | `string` |
| location | The Azure region where the Redis cache will be created. | `string` |
| sku_name | The SKU name of the Redis cache. Valid values are: Basic, Standard, Premium. | `string` |
| family | The family of the SKU. Valid values are: C (Basic/Standard) or P (Premium). | `string` |
| capacity | The size of the Redis cache to deploy. For C family (0-6), for P family (1-5). | `number` |

### Optional

| Name | Description | Type | Default |
|------|-------------|------|---------|
| minimum_tls_version | The minimum TLS version. Valid values are: 1.0, 1.1, 1.2. | `string` | `"1.2"` |
| public_network_access_enabled | Whether public network access is enabled. | `bool` | `true` |
| enable_non_ssl_port | Whether the non-SSL port is enabled. | `bool` | `false` |
| maxmemory_policy | The eviction policy when max memory is reached. | `string` | `"allkeys-lru"` |
| shard_count | Number of shards (Premium only). | `number` | `null` |
| subnet_id | Subnet ID for private endpoint integration. | `string` | `null` |
| custom_zones | Availability zones for Premium tier. | `list(string)` | `[1, 2, 3]` |
| enable_authentication | Enable authentication with access keys. | `bool` | `true` |
| tags | A map of tags to apply to the resources. | `map(string)` | `{}` |
| lock_enabled | Whether to enable the management lock for the Redis cache. | `bool` | `false` |
| lock_kind | The type of management lock. Valid values are: 'CanNotDelete', 'ReadOnly'. | `string` | `"CanNotDelete"` |

### Private Endpoint

| Name | Description | Type | Default |
|------|-------------|------|---------|
| private_endpoint_enabled | Enable private endpoint for secure VNet connectivity. | `bool` | `false` |
| private_endpoint_subnet_id | Subnet ID where the private endpoint will be created. | `string` | `null` |
| private_endpoint_name | Custom name for the private endpoint. | `string` | `null` |

### Alerting

| Name | Description | Type | Default |
|------|-------------|------|---------|
| action_group_enabled | Enable alert action group for notifications. | `bool` | `false` |
| action_group_name | Custom name for the action group. | `string` | `null` |
| alert_email_receivers | Email addresses for alert notifications. | `list(string)` | `[]` |
| alert_high_cpu_threshold | CPU percentage threshold for high CPU alert (0-100). | `number` | `80` |
| alert_high_memory_threshold | Memory percentage threshold for high memory alert (0-100). | `number` | `80` |
| alert_eviction_threshold | Evictions per second threshold for eviction alert. | `number` | `100` |
| alert_connection_failures_threshold | Connection failures per minute threshold. | `number` | `10` |

## Outputs

| Name | Description |
|------|-------------|
| id | The ID of the Redis cache. |
| name | The name of the Redis cache. |
| hostname | The hostname/FQDN of the Redis cache. |
| port | The non-SSL port of the Redis cache. |
| ssl_port | The SSL port of the Redis cache. |
| primary_connection_string | The primary connection string (sensitive). |
| secondary_connection_string | The secondary connection string (sensitive). |
| primary_access_key | The primary access key (sensitive). |
| secondary_access_key | The secondary access key (sensitive). |
| private_endpoint_id | The ID of the private endpoint (if created). |
| private_endpoint_name | The name of the private endpoint (if created). |
| action_group_id | The ID of the action group (if created). |
| metric_alert_cpu_id | The ID of the high CPU metric alert (if created). |
| metric_alert_memory_id | The ID of the high memory metric alert (if created). |
| metric_alert_evictions_id | The ID of the evictions metric alert (if created). |
| metric_alert_connections_id | The ID of the connection failures metric alert (if created). |

## SKU and Family Reference

| SKU | Family | Capacity Range | Use Case |
|-----|--------|---|----------|
| Basic | C | 0-6 | Development, test, non-critical data |
| Standard | C | 0-6 | Production cache with replication |
| Premium | P | 1-5 | High performance, clustering, persistence |

## Notes

- Redis Cache is a fully managed in-memory data store suitable for caching, session storage, and pub/sub messaging.
- TLS 1.2 is the recommended minimum for security.
- Private endpoint provides VNet-only connectivity, blocking all internet access.
- Metric alerts require action_group_enabled = true and alert_email_receivers to be effective.
- Alert thresholds should be adjusted based on your application's performance requirements.

## Examples

### Development Cache
```hcl
module "redis_dev" {
  source = "./redis_managed"

  name                = "dev-cache"
  resource_group_name = azurerm_resource_group.dev.name
  location            = azurerm_resource_group.dev.location
  sku_name            = "Basic"
  family              = "C"
  capacity            = 0

  tags = {
    Environment = "development"
  }
}
```

### Production Cache with Replication
```hcl
module "redis_prod" {
  source = "./redis_managed"

  name                = "prod-cache"
  resource_group_name = azurerm_resource_group.prod.name
  location            = azurerm_resource_group.prod.location
  sku_name            = "Standard"
  family              = "C"
  capacity            = 3

  minimum_tls_version = "1.2"
  lock_enabled        = true

  tags = {
    Environment = "production"
    CostCenter  = "engineering"
  }
}
```

### Premium Cache with Private Endpoint and Monitoring
```hcl
module "redis_premium" {
  source = "./redis_managed"

  name                = "premium-cache"
  resource_group_name = azurerm_resource_group.prod.name
  location            = azurerm_resource_group.prod.location
  sku_name            = "Premium"
  family              = "P"
  capacity            = 3

  minimum_tls_version           = "1.2"
  lock_enabled                  = true
  lock_kind                     = "CanNotDelete"
  private_endpoint_enabled      = true
  private_endpoint_subnet_id    = azurerm_subnet.private_endpoints.id

  action_group_enabled = true
  alert_email_receivers = [
    "devops@company.com",
    "platform-team@company.com"
  ]
  alert_high_cpu_threshold             = 65
  alert_high_memory_threshold          = 70
  alert_eviction_threshold             = 75
  alert_connection_failures_threshold  = 8

  tags = {
    Environment = "production"
    Monitoring  = "enabled"
  }
}
```

