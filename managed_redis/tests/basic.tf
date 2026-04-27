resource "azurerm_resource_group" "example" {
  name     = "rg-managed-redis-${var.environment}"
  location = var.location

  tags = {
    Environment = var.environment
  }
}

module "managed_redis_basic" {
  source = "../"

  name                = "redismgd${var.environment}"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  sku_name                  = "Enterprise_E5"
  high_availability_enabled = false
  public_network_access     = "Disabled"

  client_protocol   = "RESP3"
  clustering_policy = "EnterpriseCluster"
  eviction_policy   = "allkeys-lru"

  tags = merge(
    azurerm_resource_group.example.tags,
    {
      ManagedBy = "Terraform"
    }
  )
}