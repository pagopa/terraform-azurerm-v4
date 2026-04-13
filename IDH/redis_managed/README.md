# Redis Managed IDH Module

The IDH Redis Managed module provides simplified, pre-configured Azure Managed Redis deployment for common use cases across different environments and tiers. It supports private endpoint connectivity and comprehensive alerting capabilities.

## Overview

This module abstracts the complexity of the underlying `redis_managed` v4 module by applying environment and tier-specific defaults from YAML configuration. Users only need to provide `product_name`, `env`, and `idh_resource_tier`, and all other configuration is loaded from the IDH configuration system.

## Usage

### Basic Usage

```hcl
module "redis" {
  source = "./IDH/redis_managed"

  product_name        = "myapp"
  env                 = "prod"
  idh_resource_tier   = "large"
  resource_group_name = azurerm_resource_group.prod.name
  location            = azurerm_resource_group.prod.location

  tags = {
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}
```

### With Private Endpoint and Custom Alert Thresholds

```hcl
module "redis_secure" {
  source = "./IDH/redis_managed"

  product_name        = "secure-app"
  env                 = "prod"
  idh_resource_tier   = "large"
  resource_group_name = azurerm_resource_group.prod.name
  location            = azurerm_resource_group.prod.location

  # Override alert settings
  alert_high_cpu_threshold            = 65
  alert_high_memory_threshold         = 70
  alert_eviction_threshold            = 75
  alert_connection_failures_threshold = 8

  tags = {
    Environment = "production"
    Monitoring  = "enabled"
  }
}
```

## How It Works

1. The IDH loader module reads configuration from `IDH/00_product_configs/redis_managed.yml` specific to your environment and tier
2. Configuration is passed to the v4 `redis_managed` module with sensible defaults
3. Resource naming follows the pattern: `{product_name}-redis-{env}-{tier}`
4. Alert and private endpoint settings are loaded from YAML with optional per-instance overrides

## Configuration Files

Configuration is managed in `IDH/00_product_configs/redis_managed.yml`:

```yaml
redis_managed:
  dev:
    small:
      resource_group_name: "my-rg-dev"
      location: "eastus"
      sku_name: "P1"
      replicas_per_master: 0
      shards_count: 1
      zones: ["1"]
      action_group_enabled: false

  test:
    medium:
      resource_group_name: "my-rg-test"
      location: "eastus"
      sku_name: "P3"
      replicas_per_master: 1
      shards_count: 2
      zones: ["1", "2", "3"]
      action_group_enabled: true
      alert_email_receivers:
        - "devops-team@company.com"
      alert_high_cpu_threshold: 80
      alert_high_memory_threshold: 80

  prod:
    medium:
      resource_group_name: "my-rg-prod"
      location: "eastus"
      sku_name: "P3"
      replicas_per_master: 1
      shards_count: 2
      zones: ["1", "2", "3"]
      lock_enabled: true
      action_group_enabled: true
      alert_email_receivers:
        - "devops-team@company.com"
        - "on-call@company.com"
      alert_high_cpu_threshold: 70
      alert_high_memory_threshold: 75

    large:
      resource_group_name: "my-rg-prod"
      location: "eastus"
      sku_name: "P4"
      replicas_per_master: 2
      shards_count: 4
      zones: ["1", "2", "3"]
      lock_enabled: true
      action_group_enabled: true
      alert_email_receivers:
        - "devops-team@company.com"
        - "alerts@company.com"
        - "on-call@company.com"
      alert_high_cpu_threshold: 65
      alert_high_memory_threshold: 70
      alert_eviction_threshold: 75
```

## Arguments

### Required

| Name | Description | Type |
|------|-------------|------|
| product_name | The name of the product/project. | `string` |
| env | The environment name (e.g., dev, test, prod). | `string` |
| idh_resource_tier | The IDH resource tier (e.g., small, medium, large). | `string` |
| resource_group_name | Resource group name where to create the Redis cache. | `string` |
| location | Azure region where the Redis cache will be created. | `string` |

### Optional

| Name | Description | Type | Default |
|------|-------------|------|---------|
| tags | Tags to apply to all created resources. | `map(any)` | `{}` |
| private_endpoint_enabled | Enable private endpoint (overrides YAML config). | `bool` | See YAML config |
| private_endpoint_subnet_id | Subnet ID for private endpoint (overrides YAML config). | `string` | See YAML config |
| action_group_enabled | Enable alerting (overrides YAML config). | `bool` | See YAML config |
| alert_email_receivers | Email addresses for alerts (overrides YAML config). | `list(string)` | See YAML config |
| alert_high_cpu_threshold | CPU threshold % (overrides YAML config). | `number` | `80` |
| alert_high_memory_threshold | Memory threshold % (overrides YAML config). | `number` | `80` |
| alert_eviction_threshold | Evictions per second (overrides YAML config). | `number` | `100` |
| alert_connection_failures_threshold | Connection failures per minute (overrides YAML config). | `number` | `10` |

## Outputs

| Name | Description |
|------|-------------|
| id | The ID of the Redis cache. |
| name | The name of the Redis cache. |
| hostname | The hostname of the Redis cache. |
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

## Supported Tiers

Tiers are defined per environment in the YAML configuration. Common patterns:

- **Development (dev)**: Small instance (P1), no replicas, single zone, no alerting
- **Testing (test)**: Medium instance (P2-P3), optional replicas, multiple zones, basic alerting
- **Production (prod)**: Large/xlarge instances (P4-P5), replicas for HA, all zones, comprehensive alerting, management locks

Add new tiers by extending the YAML configuration in `IDH/00_product_configs/redis_managed.yml`.

## Examples

### Development Environment

```hcl
module "redis_dev" {
  source = "./IDH/redis_managed"

  product_name        = "myapp"
  env                 = "dev"
  idh_resource_tier   = "small"
  resource_group_name = azurerm_resource_group.dev.name
  location            = azurerm_resource_group.dev.location

  tags = {
    Environment = "development"
  }
}

output "dev_connection_string" {
  value     = module.redis_dev.primary_connection_string
  sensitive = true
}
```

### Production Environment with Monitoring

```hcl
module "redis_prod" {
  source = "./IDH/redis_managed"

  product_name        = "myapp"
  env                 = "prod"
  idh_resource_tier   = "large"
  resource_group_name = azurerm_resource_group.prod.name
  location            = azurerm_resource_group.prod.location

  # Fine-tune alerting for this specific instance
  alert_high_cpu_threshold = 60

  tags = {
    Environment = "production"
    Monitoring  = "enabled"
  }
}

output "prod_hostname" {
  value = module.redis_prod.hostname
}

output "prod_action_group" {
  value = module.redis_prod.action_group_id
}
```

## Notes

- All configuration should be in `IDH/00_product_configs/redis_managed.yml`; code changes should rarely be needed
- This module is subject to CODEOWNERS for the `/IDH/` directory
- Connection strings are marked sensitive; use with care
- For tier-specific customization, update the YAML configuration, not the module code
- Alert thresholds in module variables override YAML configuration when provided
- Private endpoint and alerting are optional and configurable per environment/tier
