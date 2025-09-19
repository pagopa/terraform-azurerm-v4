output "id" {
  value = module.subnet.id
}

output "subnet_id" {
  value = module.subnet.id
}

output "name" {
  value = module.subnet.name
}

output "subnet_name" {
  value = module.subnet.name
}

output "address_prefixes" {
  value = module.subnet.address_prefixes
}

output "virtual_network_name" {
  value = module.subnet.virtual_network_name
}

output "resource_group_name" {
  value = module.subnet.resource_group_name
}

output "first_ip_address" {
  value       = data.external.subnet_cidr.result.first
  description = "First usable ip address in the subnet"
}

output "last_ip_address" {
  value       = data.external.subnet_cidr.result.last
  description = "Last usable ip address in the subnet"
}
