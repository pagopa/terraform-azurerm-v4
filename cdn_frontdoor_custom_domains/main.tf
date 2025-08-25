locals {
  name_prefix      = var.cdn_prefix_name
  fd_profile_name  = "${local.name_prefix}-cdn-profile"
  fd_endpoint_name = "${local.name_prefix}-cdn-endpoint"
  keyvault_id      = var.keyvault_id

  domains          = { for d in var.custom_domains : d.domain_name => d }
  is_apex          = { for k, v in local.domains : k => (v.domain_name == v.dns_name) }
  hostname_label   = { for k, v in local.domains : k => (local.is_apex[k] ? "" : trimsuffix(replace(v.domain_name, v.dns_name, ""), ".")) }
  dns_txt_name     = { for k, v in local.domains : k => (local.is_apex[k] ? "_dnsauth" : "_dnsauth.${local.hostname_label[k]}") }
}

#----------------------------------------------------------------------------------------
# Data Sources
#----------------------------------------------------------------------------------------
data "azurerm_cdn_frontdoor_profile" "cdn" {
  name                = local.fd_profile_name
  resource_group_name = var.resource_group_name
}

data "azurerm_cdn_frontdoor_endpoint" "cdn_endpoint" {
  name                = local.fd_endpoint_name
  profile_name        = data.azurerm_cdn_frontdoor_profile.cdn.name
  resource_group_name = data.azurerm_cdn_frontdoor_profile.cdn.resource_group_name
}

data "azurerm_dns_zone" "zones" {
  for_each            = local.domains
  name                = each.value.dns_name
  resource_group_name = each.value.dns_resource_group_name
}

data "azurerm_key_vault_certificate" "certs" {
  for_each     = { for k, v in local.domains : k => v if local.is_apex[k] }
  name         = replace(each.key, ".", "-")
  key_vault_id = local.keyvault_id
  depends_on   = [azurerm_key_vault_access_policy.afd_policy]
}

#----------------------------------------------------------------------------------------
# Resources
#----------------------------------------------------------------------------------------
resource "azurerm_cdn_frontdoor_secret" "cert_secrets" {
  for_each                 = data.azurerm_key_vault_certificate.certs
  name                     = replace(each.key, ".", "-")
  cdn_frontdoor_profile_id = data.azurerm_cdn_frontdoor_profile.cdn.id
  secret {
    customer_certificate {
      key_vault_certificate_id = each.value.versionless_id
    }
  }
}

resource "azurerm_cdn_frontdoor_custom_domain" "this" {
  for_each                 = local.domains
  name                     = replace(each.key, ".", "-")
  cdn_frontdoor_profile_id = data.azurerm_cdn_frontdoor_profile.cdn.id
  dns_zone_id              = data.azurerm_dns_zone.zones[each.key].id
  host_name                = each.key
  tls {
    certificate_type        = contains(keys(azurerm_cdn_frontdoor_secret.cert_secrets), each.key) ? "CustomerCertificate" : "ManagedCertificate"
    cdn_frontdoor_secret_id = contains(keys(azurerm_cdn_frontdoor_secret.cert_secrets), each.key) ? azurerm_cdn_frontdoor_secret.cert_secrets[each.key].id : null
  }
}

resource "azurerm_dns_txt_record" "validation" {
  for_each = {
    for k, v in azurerm_cdn_frontdoor_custom_domain.this :
    k => v
    if try(v.validation_token, "") != "" && try(local.domains[k].enable_dns_records, true)
  }

  name                = local.dns_txt_name[each.key]
  zone_name           = local.domains[each.key].dns_name
  resource_group_name = local.domains[each.key].dns_resource_group_name
  ttl                 = try(local.domains[each.key].ttl, 3600)

  record { value = azurerm_cdn_frontdoor_custom_domain.this[each.key].validation_token }
}

resource "azurerm_dns_a_record" "apex" {
  for_each            = { for k, v in local.domains : k => v if local.is_apex[k] && v.enable_dns_records }
  name                = "@"
  zone_name           = each.value.dns_name
  resource_group_name = each.value.dns_resource_group_name
  ttl                 = each.value.ttl
  target_resource_id  = data.azurerm_cdn_frontdoor_endpoint.cdn_endpoint.id
}

resource "azurerm_dns_cname_record" "subdomain" {
  for_each            = { for k, v in local.domains : k => v if !local.is_apex[k] && v.enable_dns_records }
  name                = local.hostname_label[each.key]
  zone_name           = each.value.dns_name
  resource_group_name = each.value.dns_resource_group_name
  ttl                 = each.value.ttl
  record              = data.azurerm_cdn_frontdoor_endpoint.cdn_endpoint.host_name
}

#----------------------------------------------------------------------------------------
# Association to Route
#----------------------------------------------------------------------------------------
resource "azurerm_cdn_frontdoor_custom_domain_association" "this" {
  for_each                       = local.domains
  cdn_frontdoor_custom_domain_id = azurerm_cdn_frontdoor_custom_domain.this[each.key].id
  cdn_frontdoor_route_ids        = [var.cdn_route_id]
}

#----------------------------------------------------------------------------------------
# Access Policy to Key Vault
#----------------------------------------------------------------------------------------
resource "azurerm_key_vault_access_policy" "afd_policy" {
  count                   = length(local.domains) > 0 && var.keyvault_id != null ? 1 : 0
  key_vault_id            = local.keyvault_id
  tenant_id               = var.tenant_id
  object_id               = data.azurerm_cdn_frontdoor_profile.cdn.identity[0].principal_id
  secret_permissions      = ["Get"]
  certificate_permissions = ["Get"]
}
