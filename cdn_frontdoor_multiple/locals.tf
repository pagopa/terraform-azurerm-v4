############################################################
# Computed Values and Orchestration
############################################################

locals {
  # Profile naming
  profile_name = var.profile.name

  # Endpoint naming: use provided name or derive from key
  endpoints_normalized = {
    for key, endpoint in var.endpoints :
    key => merge(endpoint, {
      actual_name = endpoint.name != null ? endpoint.name : "${var.profile.name}-${key}"
    })
  }

  # Origin naming: derive host header from host_name if not provided.
  # When the static-website storage account is enabled and attached to an
  # origin group, it is injected here as an additional origin so it is created
  # as a regular azurerm_cdn_frontdoor_origin.
  origins_normalized = merge(
    {
      for key, origin in var.origins :
      key => merge(origin, {
        actual_host_header = origin.origin_host_header != null ? origin.origin_host_header : origin.host_name
      })
    },
    local.storage_origin_enabled ? {
      (local.storage_origin_key) = {
        host_name          = local.storage_origin_host
        type               = "storage"
        http_port          = 80
        https_port         = 443
        origin_host_header = local.storage_origin_host
        priority           = 1
        weight             = 1000
        enabled            = true
        actual_host_header = local.storage_origin_host
      }
    } : {}
  )

  # Origin group naming
  origin_groups_normalized = {
    for key, og in var.origin_groups :
    key => merge(og, {
      actual_name = replace(key, "-", "")
    })
  }

  # Origin groups with the static-website storage origin injected into the
  # members of its target group. Used to assign the storage origin to its group
  # and to make routes pointing to that group include the storage origin.
  origin_groups_with_storage = {
    for og_key, og in var.origin_groups :
    og_key => merge(og, {
      members = (
        local.storage_origin_enabled && og_key == var.storage_account.origin_group
        ? concat(og.members, [local.storage_origin_key])
        : og.members
      )
    })
  }

  # Ruleset naming: remove hyphens for Azure naming
  rulesets_normalized = {
    for key, ruleset in var.rulesets :
    key => merge(ruleset, {
      actual_name = replace(key, "-", "")
    })
  }

  # Flatten rulesets → rules with context
  # Result: { "security:force-https": {...rule with ruleset context...}, ... }
  rules_flattened = merge([
    for ruleset_key, ruleset in var.rulesets : {
      for rule_key, rule in ruleset.rules :
      "${ruleset_key}:${rule_key}" => merge(rule, {
        ruleset_key  = ruleset_key
        ruleset_name = local.rulesets_normalized[ruleset_key].actual_name
        rule_key     = rule_key
        rule_name    = rule_key
      })
    }
  ]...)

  # Map route name → ruleset IDs (for dependencies)
  route_rulesets = {
    for route_key, route in var.routes :
    route_key => [
      for ruleset_key in try(route.rulesets, []) :
      azurerm_cdn_frontdoor_rule_set.rulesets[ruleset_key].id
    ]
  }

  # Group origins by type for conditional creation
  origins_by_type = {
    storage = {
      for key, origin in var.origins :
      key => origin if origin.type == "storage"
    }
    app_service = {
      for key, origin in var.origins :
      key => origin if origin.type == "app_service"
    }
    function = {
      for key, origin in var.origins :
      key => origin if origin.type == "function"
    }
    custom = {
      for key, origin in var.origins :
      key => origin if origin.type == "custom"
    }
  }

  # Custom domains that need certificates from Key Vault
  domains_with_customer_certificates = {
    for key, domain in var.custom_domains :
    key => domain if domain.certificate_type == "CustomerCertificate"
  }

  # Custom domains that use managed certificates
  domains_with_managed_certificates = {
    for key, domain in var.custom_domains :
    key => domain if domain.certificate_type == "Managed"
  }

  # Domains that need DNS records (non-apex or specified)
  domains_needing_dns_records = {
    for key, domain in var.custom_domains :
    key => domain if domain.enable_dns_records
  }

  # Determine if domain is apex or subdomain
  domain_is_apex = {
    for domain_key, domain in var.custom_domains :
    domain_key => (domain_key == domain.dns_zone_name)
  }

  # Extract hostname prefix for subdomains
  domain_hostname_label = {
    for domain_key, domain in var.custom_domains :
    domain_key => local.domain_is_apex[domain_key] ? "" : trimsuffix(replace(domain_key, domain.dns_zone_name, ""), ".")
  }

  # DNS TXT validation record names
  domain_dns_txt_name = {
    for domain_key, domain in var.custom_domains :
    domain_key => local.domain_is_apex[domain_key] ? "_dnsauth" : "_dnsauth.${local.domain_hostname_label[domain_key]}"
  }
}
