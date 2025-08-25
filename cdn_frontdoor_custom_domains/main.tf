############################################################
# Locals (naming, helpers)
############################################################
locals {
  name_prefix          = var.cdn_prefix_name
  # cdn_location         = coalesce(var.cdn_location, var.location)
  # storage_account_name = var.storage_account_name != null ? replace(var.storage_account_name, "-", "") : replace("${local.name_prefix}-sa", "-", "")

  # DNS helpers computed only when custom domain is enabled
  is_apex        = var.enable_custom_domain ? var.hostname == var.dns_zone_name : false
  hostname_label = var.enable_custom_domain ? (local.is_apex ? "" : trimsuffix(replace(var.hostname, var.dns_zone_name, ""), ".")) : ""
  dns_txt_name   = var.enable_custom_domain ? (local.hostname_label != "" ? "_dnsauth.${local.hostname_label}" : "_dnsauth") : ""

  # Naming
  fd_profile_name   = "${local.name_prefix}-cdn-profile"
  fd_endpoint_name  = "${local.name_prefix}-cdn-endpoint"
  # fd_origin_group   = "origin-group"
  # fd_origin_primary = "origin-group-primary"
  # fd_route_default  = "route-default"
  # fd_ruleset_global = replace("ruleset-global", "-", "")
  # fd_rule_global    = replace("rule-global", "-", "")
  # fd_diag_name      = "tf-diagnostics"
  fd_secret_name    = "secret-certificate"
  fd_customdom_name = var.enable_custom_domain ? replace(var.hostname, ".", "-") : ""

  # Certificate helpers
  keyvault_id        = var.keyvault_id
  certificate_name   = var.enable_custom_domain ? replace(var.hostname, ".", "-") : ""
  use_kv_certificate = var.enable_custom_domain ? (var.dns_zone_name == var.hostname || var.custom_hostname_kv_enabled) : false
}

data azurerm_cdn_frontdoor_profile "cdn" {
  name                = local.fd_profile_name
  resource_group_name = var.resource_group_name
}

data azurerm_cdn_frontdoor_endpoint "cdn_endpoint" {
  name                     = local.fd_endpoint_name
  profile_name             = data.azurerm_cdn_frontdoor_profile.cdn.name
  resource_group_name      = data.azurerm_cdn_frontdoor_profile.cdn.resource_group_name
}

data "azurerm_dns_zone" "this" {
  count               = var.enable_custom_domain ? 1 : 0
  name                = var.dns_zone_name
  resource_group_name = var.dns_zone_resource_group_name
}

data "azurerm_key_vault_certificate" "custom_domain" {
  count        = var.enable_custom_domain && local.use_kv_certificate ? 1 : 0
  name         = local.certificate_name
  key_vault_id = local.keyvault_id
}

############################################################
# 🌐 Custom domain + TLS (managed or KV) — conditional
############################################################
# Entire block is skipped when enable_custom_domain = false.
# Also skips DNS data source and records in that case.

resource "azurerm_cdn_frontdoor_secret" "this" {
  count                    = var.enable_custom_domain && local.use_kv_certificate ? 1 : 0
  name                     = local.fd_secret_name
  cdn_frontdoor_profile_id = data.azurerm_cdn_frontdoor_profile.cdn.id

  secret {
    customer_certificate {
      key_vault_certificate_id = data.azurerm_key_vault_certificate.custom_domain[0].versionless_id
    }
  }
}

resource "azurerm_cdn_frontdoor_custom_domain" "this" {
  count                    = var.enable_custom_domain ? 1 : 0
  name                     = local.fd_customdom_name
  cdn_frontdoor_profile_id = data.azurerm_cdn_frontdoor_profile.cdn.id
  dns_zone_id              = var.enable_custom_domain ? data.azurerm_dns_zone.this[0].id : null
  host_name                = var.hostname

  tls {
    certificate_type        = local.use_kv_certificate ? "CustomerCertificate" : "ManagedCertificate"
    cdn_frontdoor_secret_id = var.enable_custom_domain && local.use_kv_certificate ? azurerm_cdn_frontdoor_secret.this[0].id : null
  }
}

resource "azurerm_dns_txt_record" "domain_validation" {
  count               = var.enable_custom_domain ? 1 : 0
  name                = local.dns_txt_name
  zone_name           = var.dns_zone_name
  resource_group_name = var.dns_zone_resource_group_name
  ttl                 = 3600

  record { value = azurerm_cdn_frontdoor_custom_domain.this[0].validation_token }
}

############################################################
# DNS records (Apex A-record or subdomain CNAME) — conditional
############################################################
resource "azurerm_dns_a_record" "apex_hostname" {
  count               = var.enable_custom_domain && local.is_apex && var.create_dns_record ? 1 : 0
  name                = "@"
  zone_name           = var.dns_zone_name
  resource_group_name = var.dns_zone_resource_group_name
  ttl                 = 3600
  target_resource_id  = data.azurerm_cdn_frontdoor_endpoint.cdn_endpoint.id
}

resource "azurerm_dns_cname_record" "hostname" {
  count               = var.enable_custom_domain && !local.is_apex && var.create_dns_record ? 1 : 0
  name                = local.hostname_label
  zone_name           = var.dns_zone_name
  resource_group_name = var.dns_zone_resource_group_name
  ttl                 = 3600
  record              = data.azurerm_cdn_frontdoor_endpoint.cdn_endpoint.host_name
}

############################################################
# Key Vault Access Policy for AFD SP (if using KV cert) — conditional
############################################################
resource "azurerm_key_vault_access_policy" "azure_cdn_frontdoor_policy" {
  count = var.enable_custom_domain && var.custom_hostname_kv_enabled ? 1 : 0

  key_vault_id = local.keyvault_id
  tenant_id    = var.tenant_id
  object_id    = data.azurerm_cdn_frontdoor_profile.cdn.identity[0].principal_id

  secret_permissions      = ["Get"]
  certificate_permissions = ["Get"]
}
