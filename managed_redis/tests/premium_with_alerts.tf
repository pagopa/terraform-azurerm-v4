terraform {
  required_version = ">= 1.9.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4"
    }
  }
}

provider "azurerm" {
  features {}
}

variable "location" {
  type    = string
  default = "eastus"
}

variable "environment" {
  type    = string
  default = "prod"
}

resource "azurerm_resource_group" "example" {
  name     = "rg-managed-redis-premium-${var.environment}"
  location = var.location

  tags = {
    Environment = var.environment
  }
}

resource "azurerm_virtual_network" "example" {
  name                = "vnet-redis"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_subnet" "redis" {
  name                 = "snet-redis"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "private_endpoint" {
  name                 = "snet-private-endpoints"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_private_dns_zone" "redis" {
  name                = "privatelink.redis.cache.windows.net"
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "redis" {
  name                  = "redis-vnet-link"
  resource_group_name   = azurerm_resource_group.example.name
  private_dns_zone_name = azurerm_private_dns_zone.redis.name
  virtual_network_id    = azurerm_virtual_network.example.id
}

resource "azurerm_monitor_action_group" "example" {
  name                = "mag-redis-${var.environment}"
  resource_group_name = azurerm_resource_group.example.name
  short_name          = "redis-ag"
}

module "managed_redis_premium" {
  source = "../"

  name                = "redismgd${var.environment}"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  # Enterprise Flash tier configuration
  sku_name                  = "EnterpriseFlash_F300"
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
    { name = "RedisJSON" }
  ]

  # Private endpoint configuration
  private_endpoint_enabled   = true
  private_endpoint_subnet_id = azurerm_subnet.private_endpoint.id
  private_dns_zone_ids       = [azurerm_private_dns_zone.redis.id]

  # Alerting configuration
  alert_action_group_ids     = [azurerm_monitor_action_group.example.id]
  enable_cpu_alerts          = true
  cpu_usage_percentage_threshold = 75
  enable_memory_alerts       = true
  memory_usage_percentage_threshold = 80
  enable_eviction_alerts     = true
  enable_connection_alerts   = true
  connection_count_threshold = 10000

  tags = merge(
    azurerm_resource_group.example.tags,
    {
      ManagedBy = "Terraform"
      Tier      = "EnterpriseFlash"
    }
  )

  depends_on = [
    azurerm_private_dns_zone_virtual_network_link.redis
  ]
}

output "redis_id" {
  value       = module.managed_redis_premium.id
  description = "The resource ID of the managed Redis instance"
}

output "redis_hostname" {
  value       = module.managed_redis_premium.hostname
  description = "The hostname for connecting to managed Redis"
}

output "private_endpoint_id" {
  value       = module.managed_redis_premium.private_endpoint_id
  description = "The ID of the private endpoint"
}
