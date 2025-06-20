output "id" {
  value = module.redis.id
}

output "name" {
  value = module.redis.name
}

output "location" {
  value = module.redis.location
}

output "resource_group_name" {
  value = module.redis.resource_group_name
}

output "hostname" {
  value = module.redis.hostname
}

output "port" {
  value = module.redis.port
}

output "ssl_port" {
  value = module.redis.ssl_port
}

output "sku" {
  value = module.redis.sku
}

#
# Access Keys
#
output "primary_access_key" {
  value     = module.redis.primary_access_key
  sensitive = true
}

output "primary_connection_string" {
  value     = module.redis.primary_connection_string
  sensitive = true
}

output "primary_connection_url" {
  # The double “s” in rediss:// for TLS is not a typo.
  value     = "rediss://:${module.redis.primary_access_key}@${module.redis.hostname}:${module.redis.ssl_port}"
  sensitive = true
}

output "secondary_access_key" {
  value     = module.redis.secondary_access_key
  sensitive = true
}

output "secondary_connection_string" {
  value     = module.redis.secondary_connection_string
  sensitive = true
}

output "secondary_connection_url" {
  # The double “s” in rediss:// for TLS is not a typo.
  value     = "rediss://:${module.redis.secondary_access_key}@${module.redis.hostname}:${module.redis.ssl_port}"
  sensitive = true
}
