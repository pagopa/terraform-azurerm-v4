<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 4 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_storage_account"></a> [storage\_account](#module\_storage\_account) | ../storage_account | n/a |

## Resources

| Name | Type |
|------|------|
| [azurerm_cdn_frontdoor_custom_domain.domains](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_custom_domain) | resource |
| [azurerm_cdn_frontdoor_endpoint.endpoints](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_endpoint) | resource |
| [azurerm_cdn_frontdoor_origin.origins](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_origin) | resource |
| [azurerm_cdn_frontdoor_origin_group.origin_groups](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_origin_group) | resource |
| [azurerm_cdn_frontdoor_profile.profile](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_profile) | resource |
| [azurerm_cdn_frontdoor_route.routes](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_route) | resource |
| [azurerm_cdn_frontdoor_rule.rules](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_rule) | resource |
| [azurerm_cdn_frontdoor_rule_set.rulesets](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_rule_set) | resource |
| [azurerm_cdn_frontdoor_secret.certificates](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_secret) | resource |
| [azurerm_dns_a_record.apex](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/dns_a_record) | resource |
| [azurerm_dns_cname_record.subdomain](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/dns_cname_record) | resource |
| [azurerm_dns_txt_record.validation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/dns_txt_record) | resource |
| [azurerm_key_vault_access_policy.afd_keyvault_policy](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_access_policy) | resource |
| [azurerm_monitor_diagnostic_setting.profile_diagnostics](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_diagnostic_setting) | resource |
| [azurerm_dns_zone.zones](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/dns_zone) | data source |
| [azurerm_key_vault_certificate.certs](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/key_vault_certificate) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_custom_domains"></a> [custom\_domains](#input\_custom\_domains) | Custom domains with DNS and certificate management | <pre>map(object({<br/>    dns_zone_name                = string<br/>    dns_zone_resource_group_name = string<br/>    certificate_type             = optional(string, "Managed")<br/>    keyvault_id                  = optional(string)<br/>    keyvault_certificate_name    = optional(string)<br/>    enable_dns_records           = optional(bool, true)<br/>    ttl                          = optional(number, 3600)<br/>  }))</pre> | `{}` | no |
| <a name="input_endpoints"></a> [endpoints](#input\_endpoints) | CDN Front Door endpoints (entry points) | <pre>map(object({<br/>    name = optional(string)<br/>  }))</pre> | n/a | yes |
| <a name="input_location"></a> [location](#input\_location) | Azure region | `string` | n/a | yes |
| <a name="input_log_analytics_workspace_id"></a> [log\_analytics\_workspace\_id](#input\_log\_analytics\_workspace\_id) | Log Analytics workspace ID for diagnostics | `string` | n/a | yes |
| <a name="input_origin_groups"></a> [origin\_groups](#input\_origin\_groups) | Origin groups (pools of backends with health checks and load balancing) | <pre>map(object({<br/>    description = optional(string, "")<br/>    members     = list(string)<br/><br/>    health_probe = optional(object({<br/>      path                = optional(string, "/")<br/>      protocol            = optional(string, "Https")<br/>      request_type        = optional(string, "GET")<br/>      interval_in_seconds = optional(number, 120)<br/>    }), {})<br/><br/>    load_balancing = optional(object({<br/>      sample_size                        = optional(number, 4)<br/>      successful_samples_required        = optional(number, 2)<br/>      additional_latency_in_milliseconds = optional(number, 0)<br/>    }), {})<br/>  }))</pre> | n/a | yes |
| <a name="input_origins"></a> [origins](#input\_origins) | Backend origins (servers/services) | <pre>map(object({<br/>    host_name          = string<br/>    type               = string<br/>    http_port          = optional(number, 80)<br/>    https_port         = optional(number, 443)<br/>    origin_host_header = optional(string)<br/>    priority           = optional(number, 1)<br/>    weight             = optional(number, 1000)<br/>    enabled            = optional(bool, true)<br/>  }))</pre> | n/a | yes |
| <a name="input_profile"></a> [profile](#input\_profile) | CDN Front Door profile configuration | <pre>object({<br/>    name = string<br/>  })</pre> | n/a | yes |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Name of the resource group | `string` | n/a | yes |
| <a name="input_routes"></a> [routes](#input\_routes) | Routes (connect endpoints → origin\_groups, apply rulesets, attach domains) | <pre>map(object({<br/>    endpoint       = string<br/>    origin_group   = string<br/>    patterns       = list(string)<br/>    protocols      = optional(list(string), ["Http", "Https"])<br/>    forwarding     = optional(string, "MatchRequest")<br/>    https_redirect = optional(bool, true)<br/>    cache_behavior = optional(string, "IgnoreQueryString")<br/>    custom_domains = optional(list(string), [])<br/>    rulesets       = optional(list(string), [])<br/>    enabled        = optional(bool, true)<br/>  }))</pre> | n/a | yes |
| <a name="input_rulesets"></a> [rulesets](#input\_rulesets) | Rulesets containing rules for request processing (headers, caching, redirects, rewrites) | <pre>map(object({<br/>    description = optional(string, "")<br/>    rules = map(object({<br/>      order             = number<br/>      behavior_on_match = optional(string, "Continue")<br/><br/>      condition = optional(object({<br/>        type         = string<br/>        operator     = string<br/>        match_values = optional(list(string), [])<br/>        negate       = optional(bool, false)<br/>        transforms   = optional(list(string), [])<br/>        selector     = optional(string)<br/>      }))<br/><br/>      conditions = optional(list(object({<br/>        type         = string<br/>        operator     = string<br/>        match_values = optional(list(string), [])<br/>        negate       = optional(bool, false)<br/>        transforms   = optional(list(string), [])<br/>        selector     = optional(string)<br/>      })), [])<br/><br/>      actions = list(object({<br/>        type     = string<br/>        protocol = optional(string)<br/>        hostname = optional(string)<br/>        path     = optional(string)<br/>        fragment = optional(string)<br/><br/>        redirect_type           = optional(string)<br/>        query_string            = optional(string)<br/>        source_pattern          = optional(string)<br/>        destination             = optional(string)<br/>        preserve_unmatched_path = optional(bool, false)<br/><br/>        behavior              = optional(string)<br/>        duration              = optional(string) # d.HH:MM:SS format (e.g. 365.23:59:59)<br/>        query_string_behavior = optional(string)<br/>        query_string_params   = optional(string)<br/><br/>        header_action = optional(string)<br/>        header_name   = optional(string)<br/>        value         = optional(string)<br/>      }))<br/>    }))<br/>  }))</pre> | `{}` | no |
| <a name="input_storage_account"></a> [storage\_account](#input\_storage\_account) | Optional storage account configuration for static website hosting. Set 'origin\_group' to the key of an origin\_group to automatically wire the static website as a CDN Front Door origin. | <pre>object({<br/>    enabled                         = optional(bool, false)<br/>    account_name                    = optional(string)<br/>    account_kind                    = optional(string, "StorageV2")<br/>    account_tier                    = optional(string, "Standard")<br/>    account_replication_type        = optional(string, "ZRS")<br/>    access_tier                     = optional(string, "Hot")<br/>    index_document                  = optional(string, "index.html")<br/>    error_404_document              = optional(string, "error.html")<br/>    nested_items_public             = optional(bool, true)<br/>    public_network_access           = optional(bool, true)<br/>    allow_nested_items_to_be_public = optional(bool, true)<br/>    threat_protection_enabled       = optional(bool, false)<br/>    origin_group                    = optional(string)<br/>  })</pre> | `{}` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to all resources | `map(string)` | `{}` | no |
| <a name="input_tenant_id"></a> [tenant\_id](#input\_tenant\_id) | Tenant ID for Key Vault access (required if using CustomerCertificate domains) | `string` | `null` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->