variable "location" {
  type    = string
  default = "eastus"
}

variable "environment" {
  type    = string
  default = "prod"
}

output "redis_hostname" {
  value       = module.managed_redis_basic.hostname
  description = "The hostname for connecting to managed Redis"
}

output "redis_id" {
  value       = module.managed_redis_basic.id
  description = "The resource ID of the managed Redis instance"
}