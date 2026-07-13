############################################################
# DNS Zones (Data Source)
############################################################

data "azurerm_dns_zone" "zones" {
  for_each = var.custom_domains

  name                = each.value.dns_zone_name
  resource_group_name = each.value.dns_zone_resource_group_name
}

############################################################
# Key Vault Certificates (Data Source)
############################################################

data "azurerm_key_vault_certificate" "certs" {
  for_each = local.domains_with_customer_certificates

  name         = each.value.keyvault_certificate_name
  key_vault_id = each.value.keyvault_id

  depends_on = [azurerm_key_vault_access_policy.afd_keyvault_policy]
}

############################################################
# Key Vault Access Policy
############################################################

resource "azurerm_key_vault_access_policy" "afd_keyvault_policy" {
  count = length(local.domains_with_customer_certificates) > 0 ? 1 : 0

  key_vault_id            = var.custom_domains[keys(local.domains_with_customer_certificates)[0]].keyvault_id
  tenant_id               = var.tenant_id
  object_id               = azurerm_cdn_frontdoor_profile.profile.identity[0].principal_id
  secret_permissions      = ["Get"]
  certificate_permissions = ["Get"]
}

############################################################
# CDN Front Door Secrets (Certificates)
############################################################

resource "azurerm_cdn_frontdoor_secret" "certificates" {
  for_each = data.azurerm_key_vault_certificate.certs

  name                     = replace(each.key, ".", "-")
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.profile.id

  secret {
    customer_certificate {
      key_vault_certificate_id = each.value.versionless_id
    }
  }
}

############################################################
# Custom Domains
############################################################

resource "azurerm_cdn_frontdoor_custom_domain" "domains" {
  for_each = var.custom_domains

  name                     = replace(each.key, ".", "-")
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.profile.id
  dns_zone_id              = data.azurerm_dns_zone.zones[each.key].id
  host_name                = each.key

  tls {
    certificate_type        = each.value.certificate_type
    cdn_frontdoor_secret_id = contains(keys(azurerm_cdn_frontdoor_secret.certificates), each.key) ? azurerm_cdn_frontdoor_secret.certificates[each.key].id : null
  }

  lifecycle {
    create_before_destroy = true
  }
}

############################################################
# DNS Records - TXT Validation (for non-apex domains)
############################################################

resource "azurerm_dns_txt_record" "validation" {
  for_each = {
    for domain_key, domain in local.domains_needing_dns_records :
    domain_key => domain
    if !local.domain_is_apex[domain_key]
  }

  name                = local.domain_dns_txt_name[each.key]
  zone_name           = each.value.dns_zone_name
  resource_group_name = each.value.dns_zone_resource_group_name
  ttl                 = each.value.ttl

  record {
    value = azurerm_cdn_frontdoor_custom_domain.domains[each.key].validation_token
  }

  lifecycle {
    precondition {
      condition     = azurerm_cdn_frontdoor_custom_domain.domains[each.key].validation_token != null && length(trimspace(azurerm_cdn_frontdoor_custom_domain.domains[each.key].validation_token)) > 0
      error_message = "Validation token for domain '${each.key}' not generated. This may be expected if domain is already validated."
    }
  }

  depends_on = [azurerm_cdn_frontdoor_custom_domain.domains]
}

############################################################
# DNS Records - A Record (for apex domains)
############################################################

resource "azurerm_dns_a_record" "apex" {
  for_each = {
    for domain_key, domain in local.domains_needing_dns_records :
    domain_key => domain
    if local.domain_is_apex[domain_key]
  }

  name                = "@"
  zone_name           = each.value.dns_zone_name
  resource_group_name = each.value.dns_zone_resource_group_name
  ttl                 = each.value.ttl
  target_resource_id = azurerm_cdn_frontdoor_endpoint.endpoints[
    # Find the first endpoint that references this domain
    [
      for route_key, route in var.routes :
      route.endpoint
      if contains(route.custom_domains, each.key)
    ][0]
  ].id
}

############################################################
# DNS Records - CNAME (for subdomain)
############################################################

resource "azurerm_dns_cname_record" "subdomain" {
  for_each = {
    for domain_key, domain in local.domains_needing_dns_records :
    domain_key => domain
    if !local.domain_is_apex[domain_key]
  }

  name                = local.domain_hostname_label[each.key]
  zone_name           = each.value.dns_zone_name
  resource_group_name = each.value.dns_zone_resource_group_name
  ttl                 = each.value.ttl
  record = azurerm_cdn_frontdoor_endpoint.endpoints[
    # Find the first endpoint that references this domain
    [
      for route_key, route in var.routes :
      route.endpoint
      if contains(route.custom_domains, each.key)
    ][0]
  ].host_name
}
