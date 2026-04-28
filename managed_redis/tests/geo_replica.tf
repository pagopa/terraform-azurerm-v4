resource "azurerm_resource_group" "example" {
  name     = "rg-managed-redis-geo-${var.environment}"
  location = var.location

  tags = {
    Environment = var.environment
  }
}

# Secondary resource group for replica in different location
resource "azurerm_resource_group" "replica" {
  name     = "rg-managed-redis-geo-replica-${var.environment}"
  location = "westeurope" # Different location for true geo-replication

  tags = {
    Environment = var.environment
  }
}

# Virtual networks for primary and replica
resource "azurerm_virtual_network" "primary" {
  name                = "vnet-redis-primary-${var.environment}"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  tags = azurerm_resource_group.example.tags
}

resource "azurerm_virtual_network" "replica" {
  name                = "vnet-redis-replica-${var.environment}"
  address_space       = ["10.1.0.0/16"]
  location            = azurerm_resource_group.replica.location
  resource_group_name = azurerm_resource_group.replica.name

  tags = azurerm_resource_group.replica.tags
}

# Subnets for private endpoints (provided as input to the module)
resource "azurerm_subnet" "primary_pep" {
  name                 = "subnet-redis-pep-${var.environment}"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.primary.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "replica_pep" {
  name                 = "subnet-redis-pep-replica-${var.environment}"
  resource_group_name  = azurerm_resource_group.replica.name
  virtual_network_name = azurerm_virtual_network.replica.name
  address_prefixes     = ["10.1.1.0/24"]
}

# Private DNS zones
resource "azurerm_private_dns_zone" "redis" {
  name                = "redisdb.internal.windows.net"
  resource_group_name = azurerm_resource_group.example.name

  tags = azurerm_resource_group.example.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "primary" {
  name                  = "link-primary"
  resource_group_name   = azurerm_resource_group.example.name
  private_dns_zone_name = azurerm_private_dns_zone.redis.name
  virtual_network_id    = azurerm_virtual_network.primary.id
}

resource "azurerm_private_dns_zone_virtual_network_link" "replica" {
  name                  = "link-replica"
  resource_group_name   = azurerm_resource_group.replica.name
  private_dns_zone_name = azurerm_private_dns_zone.redis.name
  virtual_network_id    = azurerm_virtual_network.replica.id
}

# Managed Redis with geo-replication replica
# NOTE: The module takes subnet IDs as input - they are not created within the module
module "managed_redis_geo_replica" {
  source = "../"

  name                = "redismgd${var.environment}"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  sku_name                  = "Balanced_B3"
  high_availability_enabled = true
  public_network_access     = "Disabled"

  client_protocol   = "Encrypted"
  clustering_policy = "EnterpriseCluster"
  eviction_policy   = "AllKeysLRU"

  # Primary private endpoint configuration - subnet provided as input
  private_endpoint_enabled   = true
  private_endpoint_subnet_id = azurerm_subnet.primary_pep.id
  private_dns_zone_ids       = [azurerm_private_dns_zone.redis.id]

  # Geo-replication configuration
  enable_geo_replication_replica = true
  geo_replication_group_name     = "redis-geo-group-${var.environment}"
  replica_name                   = "redismgd${var.environment}-replica"
  replica_location               = azurerm_resource_group.replica.location

  # Replica private endpoint configuration - subnet provided as input (different from primary)
  replica_private_endpoint_enabled   = true
  replica_private_endpoint_subnet_id = azurerm_subnet.replica_pep.id
  replica_private_dns_zone_ids       = [azurerm_private_dns_zone.redis.id]

  # Monitoring configuration - applies to both primary and replica
  enable_cpu_alerts                 = true
  cpu_usage_percentage_threshold    = 80
  enable_memory_alerts              = true
  memory_usage_percentage_threshold = 85
  enable_eviction_alerts            = true
  enable_connection_alerts          = true
  connection_count_threshold        = 10000
  alert_action_group_ids            = [] # Add your action group IDs here

  tags = merge(
    azurerm_resource_group.example.tags,
    {
      ManagedBy   = "Terraform"
      Replication = "Enabled"
    }
  )
}

# Outputs for demonstration
output "primary_redis_id" {
  value = module.managed_redis_geo_replica.id
}

output "primary_redis_hostname" {
  value = module.managed_redis_geo_replica.hostname
}

output "replica_redis_id" {
  value = module.managed_redis_geo_replica.replica_id
}

output "replica_redis_hostname" {
  value = module.managed_redis_geo_replica.replica_hostname
}

