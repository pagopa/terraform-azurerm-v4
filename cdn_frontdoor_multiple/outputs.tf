############################################################
# Profile
############################################################
output "profile_id" {
  description = "ID of the CDN Front Door profile"
  value       = azurerm_cdn_frontdoor_profile.profile.id
}

output "profile_name" {
  description = "Name of the CDN Front Door profile"
  value       = azurerm_cdn_frontdoor_profile.profile.name
}

output "profile_identity_principal_id" {
  description = "Principal ID of the profile's system-assigned managed identity (used for Key Vault access)"
  value       = azurerm_cdn_frontdoor_profile.profile.identity[0].principal_id
}

############################################################
# Endpoints
############################################################
output "endpoint_ids" {
  description = "Map of endpoint key => CDN Front Door endpoint ID"
  value       = { for key, endpoint in azurerm_cdn_frontdoor_endpoint.endpoints : key => endpoint.id }
}

output "endpoint_hostnames" {
  description = "Map of endpoint key => default CDN Front Door hostname (e.g. to create CNAME/ALIAS records)"
  value       = { for key, endpoint in azurerm_cdn_frontdoor_endpoint.endpoints : key => endpoint.host_name }
}

############################################################
# Origin Groups and Origins
############################################################
output "origin_group_ids" {
  description = "Map of origin_group key => CDN Front Door origin group ID"
  value       = { for key, origin_group in azurerm_cdn_frontdoor_origin_group.origin_groups : key => origin_group.id }
}

output "origin_ids" {
  description = "Map of origin key => CDN Front Door origin ID (only origins declared in var.origins, excludes the auto-injected storage origin)"
  value       = { for key, origin in azurerm_cdn_frontdoor_origin.origins : key => origin.id if contains(keys(var.origins), key) }
}

############################################################
# Routes
############################################################
output "route_ids" {
  description = "Map of route key => CDN Front Door route ID"
  value       = { for key, route in azurerm_cdn_frontdoor_route.routes : key => route.id }
}

############################################################
# Rule Sets
############################################################
output "ruleset_ids" {
  description = "Map of ruleset key => CDN Front Door rule set ID"
  value       = { for key, ruleset in azurerm_cdn_frontdoor_rule_set.rulesets : key => ruleset.id }
}

############################################################
# Custom Domains
############################################################
output "custom_domain_ids" {
  description = "Map of custom domain (hostname) => CDN Front Door custom domain ID"
  value       = { for key, domain in azurerm_cdn_frontdoor_custom_domain.domains : key => domain.id }
}

############################################################
# Storage Account (static website), when enabled
############################################################
output "storage_account_id" {
  description = "ID of the static-website storage account, if enabled"
  value       = one(module.storage_account[*].id)
}

output "storage_account_name" {
  description = "Name of the static-website storage account, if enabled"
  value       = one(module.storage_account[*].name)
}

output "storage_account_primary_web_host" {
  description = "Primary static website host of the storage account, if enabled (the host wired as CDN origin)"
  value       = one(module.storage_account[*].primary_web_host)
}
