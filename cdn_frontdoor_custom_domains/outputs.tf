output "profile_id" {
  value = data.azurerm_cdn_frontdoor_profile.cdn.id
}

output "profile_name" {
  value = data.azurerm_cdn_frontdoor_profile.cdn.name
}

output "endpoint_id" {
  value = data.azurerm_cdn_frontdoor_endpoint.cdn_endpoint.id
}

output "id" {
  value       = data.azurerm_cdn_frontdoor_endpoint.cdn_endpoint.id
  description = "Deprecated, use endpoint_id instead."
}

output "endpoint_name" {
  value = data.azurerm_cdn_frontdoor_endpoint.cdn_endpoint.name
}

output "hostname" {
  value = data.azurerm_cdn_frontdoor_endpoint.cdn_endpoint.host_name
}

output "fqdn" {
  value = data.azurerm_cdn_frontdoor_endpoint.cdn_endpoint.host_name
}

# Custom domains
output "custom_domain_hostnames" {
  description = "Lista degli hostnames configurati su Front Door."
  value       = [for k, v in azurerm_cdn_frontdoor_custom_domain.this : v.host_name]
}

output "custom_domain_validation_tokens" {
  description = "Mappa hostname → validation token per TXT record."
  value       = { for k, v in azurerm_cdn_frontdoor_custom_domain.this : k => v.validation_token }
}

output "dns_txt_records" {
  description = "Mappa degli TXT records creati per validazione dominio."
  value       = { for k, v in azurerm_dns_txt_record.validation : k => v.fqdn }
}

output "dns_a_records" {
  description = "Mappa degli A records creati (solo domini apex con enable_dns_records=true)."
  value       = { for k, v in azurerm_dns_a_record.apex : k => v.fqdn }
}

output "dns_cname_records" {
  description = "Mappa dei CNAME records creati (solo subdomains con enable_dns_records=true)."
  value       = { for k, v in azurerm_dns_cname_record.subdomain : k => v.fqdn }
}
