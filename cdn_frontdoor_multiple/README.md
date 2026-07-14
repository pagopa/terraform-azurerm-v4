# CDN Front Door (Multiple)

This module provisions an Azure Front Door (Standard SKU) profile supporting **multiple endpoints, origin groups, routes, rulesets and custom domains** in a single instance. It is designed for scenarios where several sites/APIs (e.g. a static web frontend and a backend API) need to share one Front Door profile.

Compared to [`cdn_frontdoor`](../cdn_frontdoor), which manages a single endpoint/domain, this module lets you declare an arbitrary number of:

- **Endpoints** — entry points for incoming traffic
- **Origins** and **origin groups** — backend pools with health probes and load balancing
- **Routes** — wiring endpoints to origin groups, with caching, protocol and forwarding settings
- **Rulesets/Rules** — request/response processing (redirects, rewrites, header manipulation, cache overrides)
- **Custom domains** — with automatic DNS record and certificate management

## Features

- Multiple endpoints, origin groups, routes and rulesets defined as maps, so you can model complex topologies (e.g. `web` + `api`) in one module call.
- Optional built-in **Storage Account with static website hosting**, automatically wired as an origin of the chosen origin group (`storage_account.origin_group`) — no need to feed its outputs back into `origins`.
- **Custom domain automation**: DNS validation TXT records, apex `A` records / subdomain `CNAME` records, and Managed or Customer (Key Vault) certificates.
- Rich rule engine covering `redirect`, `rewrite`, `cache`, `request_header` and `response_header` actions, with single or multiple match conditions per rule (URL path, query string, headers, cookies, device type, etc.).
- Diagnostic settings sent to a Log Analytics workspace for the whole profile.
- Input validation to catch common misconfigurations at `plan` time (dangling references between routes/origin_groups/origins/rulesets/domains, invalid operators, apex domains with `ManagedCertificate`, etc.).

## Notes

- Apex domains (domain name == DNS zone name) require `certificate_type = "CustomerCertificate"`; Azure Front Door does not support managed certificates on the zone apex.
- `CustomerCertificate` domains require `keyvault_id`, `keyvault_certificate_name` and `tenant_id` (used to grant the Front Door managed identity access to the Key Vault).
- When `storage_account.enabled = true` and `storage_account.origin_group` is set, do **not** declare that storage origin manually in `origins` — the module injects it automatically into the target origin group's members.
- Origin groups can have `members = []` only if they are the target of the auto-injected storage origin.
- `route.link_to_default_domain` defaults to `true` when the route has no `custom_domains` (so it stays reachable via the endpoint's default `*.azurefd.net` hostname) and to `false` when it has at least one custom domain. Set it explicitly to override this behavior.

## Usage Example

```hcl
module "cdn" {
  source = "github.com/pagopa/terraform-azurerm-v4//cdn_frontdoor_multiple"

  resource_group_name        = azurerm_resource_group.this.name
  location                   = "italynorth"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id
  tenant_id                  = data.azurerm_client_config.current.tenant_id

  profile = {
    name = "example-cdn"
  }

  # Optional: static website storage account, auto-wired as origin of "web-pool"
  storage_account = {
    enabled                   = true
    account_name              = "examplecdnsa"
    account_replication_type  = "ZRS"
    index_document             = "index.html"
    error_404_document         = "error.html"
    origin_group               = "web-pool"
  }

  endpoints = {
    "web" = { name = "example-cdn-web" }
    "api" = { name = "example-cdn-api" }
  }

  # The storage origin is injected automatically into "web-pool", so it must
  # NOT be declared here.
  origins = {
    "api-backend" = {
      host_name  = "backend.example.com"
      https_port = 443
      priority   = 1
      weight     = 1000
    }
  }

  origin_groups = {
    "web-pool" = {
      description = "Static website pool"
      members     = []
      health_probe = {
        path     = "/"
        protocol = "Https"
      }
    }
    "api-pool" = {
      description = "API backend pool"
      members     = ["api-backend"]
      health_probe = {
        path     = "/health"
        protocol = "Https"
      }
    }
  }

  routes = {
    "web-default" = {
      endpoint       = "web"
      origin_group   = "web-pool"
      patterns       = ["/*"]
      cache_behavior = "IgnoreQueryString"
      custom_domains = ["www.example.com"]
      rulesets       = ["WebSecurity"]
    }
    "api-route" = {
      endpoint       = "api"
      origin_group   = "api-pool"
      patterns       = ["/api/*"]
      cache_behavior = "UseQueryString"
      custom_domains = ["api.example.com"]
    }
  }

  rulesets = {
    "WebSecurity" = {
      description = "Security headers for the web endpoint"
      rules = {
        "SecurityHeaders" = {
          order      = 10
          conditions = []
          actions = [{
            type          = "response_header"
            header_action = "Append"
            header_name   = "Strict-Transport-Security"
            value         = "max-age=31536000; includeSubDomains"
          }]
        }
      }
    }
  }

  custom_domains = {
    "www.example.com" = {
      dns_zone_name                = "example.com"
      dns_zone_resource_group_name = "example-dns-rg"
      certificate_type             = "ManagedCertificate"
    }
    "api.example.com" = {
      dns_zone_name                = "example.com"
      dns_zone_resource_group_name = "example-dns-rg"
      certificate_type             = "ManagedCertificate"
    }
  }

  tags = {
    Environment = "prod"
  }
}
```

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
| <a name="input_custom_domains"></a> [custom\_domains](#input\_custom\_domains) | Custom domains with DNS and certificate management | <pre>map(object({<br/>    dns_zone_name                = string<br/>    dns_zone_resource_group_name = string<br/>    certificate_type             = optional(string, "ManagedCertificate")<br/>    keyvault_id                  = optional(string)<br/>    keyvault_certificate_name    = optional(string)<br/>    enable_dns_records           = optional(bool, true)<br/>    ttl                          = optional(number, 3600)<br/>  }))</pre> | `{}` | no |
| <a name="input_endpoints"></a> [endpoints](#input\_endpoints) | CDN Front Door endpoints (entry points) | <pre>map(object({<br/>    name = optional(string)<br/>  }))</pre> | n/a | yes |
| <a name="input_location"></a> [location](#input\_location) | Azure region | `string` | n/a | yes |
| <a name="input_log_analytics_workspace_id"></a> [log\_analytics\_workspace\_id](#input\_log\_analytics\_workspace\_id) | Log Analytics workspace ID for diagnostics | `string` | n/a | yes |
| <a name="input_origin_groups"></a> [origin\_groups](#input\_origin\_groups) | Origin groups (pools of backends with health checks and load balancing) | <pre>map(object({<br/>    description = optional(string, "")<br/>    members     = list(string)<br/><br/>    health_probe = optional(object({<br/>      path                = optional(string, "/")<br/>      protocol            = optional(string, "Https")<br/>      request_type        = optional(string, "GET")<br/>      interval_in_seconds = optional(number, 120)<br/>    }), {})<br/><br/>    load_balancing = optional(object({<br/>      sample_size                        = optional(number, 4)<br/>      successful_samples_required        = optional(number, 2)<br/>      additional_latency_in_milliseconds = optional(number, 0)<br/>    }), {})<br/>  }))</pre> | n/a | yes |
| <a name="input_origins"></a> [origins](#input\_origins) | Backend origins (servers/services) | <pre>map(object({<br/>    host_name          = string<br/>    http_port          = optional(number, 80)<br/>    https_port         = optional(number, 443)<br/>    origin_host_header = optional(string)<br/>    priority           = optional(number, 1)<br/>    weight             = optional(number, 1000)<br/>    enabled            = optional(bool, true)<br/>  }))</pre> | n/a | yes |
| <a name="input_profile"></a> [profile](#input\_profile) | CDN Front Door profile configuration | <pre>object({<br/>    name = string<br/>  })</pre> | n/a | yes |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Name of the resource group | `string` | n/a | yes |
| <a name="input_routes"></a> [routes](#input\_routes) | Routes (connect endpoints → origin\_groups, apply rulesets, attach domains) | <pre>map(object({<br/>    endpoint               = string<br/>    origin_group           = string<br/>    patterns               = list(string)<br/>    protocols              = optional(list(string), ["Http", "Https"])<br/>    forwarding             = optional(string, "MatchRequest")<br/>    https_redirect         = optional(bool, true)<br/>    cache_behavior         = optional(string, "IgnoreQueryString")<br/>    custom_domains         = optional(list(string), [])<br/>    rulesets               = optional(list(string), [])<br/>    enabled                = optional(bool, true)<br/>    link_to_default_domain = optional(bool)<br/>  }))</pre> | n/a | yes |
| <a name="input_rulesets"></a> [rulesets](#input\_rulesets) | Rulesets containing rules for request processing (headers, caching, redirects, rewrites) | <pre>map(object({<br/>    description = optional(string, "")<br/>    rules = map(object({<br/>      order             = number<br/>      behavior_on_match = optional(string, "Continue")<br/><br/>      condition = optional(object({<br/>        type         = string<br/>        operator     = string<br/>        match_values = optional(list(string), [])<br/>        negate       = optional(bool, false)<br/>        transforms   = optional(list(string), [])<br/>        selector     = optional(string)<br/>      }))<br/><br/>      conditions = optional(list(object({<br/>        type         = string<br/>        operator     = string<br/>        match_values = optional(list(string), [])<br/>        negate       = optional(bool, false)<br/>        transforms   = optional(list(string), [])<br/>        selector     = optional(string)<br/>      })), [])<br/><br/>      actions = list(object({<br/>        type     = string<br/>        protocol = optional(string)<br/>        hostname = optional(string)<br/>        path     = optional(string)<br/>        fragment = optional(string)<br/><br/>        redirect_type           = optional(string)<br/>        query_string            = optional(string)<br/>        source_pattern          = optional(string)<br/>        destination             = optional(string)<br/>        preserve_unmatched_path = optional(bool, false)<br/><br/>        behavior              = optional(string)<br/>        duration              = optional(string) # d.HH:MM:SS format (e.g. 365.23:59:59)<br/>        query_string_behavior = optional(string)<br/>        query_string_params   = optional(string)<br/><br/>        header_action = optional(string)<br/>        header_name   = optional(string)<br/>        value         = optional(string)<br/>      }))<br/>    }))<br/>  }))</pre> | `{}` | no |
| <a name="input_storage_account"></a> [storage\_account](#input\_storage\_account) | Optional storage account configuration for static website hosting. Set 'origin\_group' to the key of an origin\_group to automatically wire the static website as a CDN Front Door origin. | <pre>object({<br/>    enabled                         = optional(bool, false)<br/>    account_name                    = optional(string)<br/>    account_kind                    = optional(string, "StorageV2")<br/>    account_tier                    = optional(string, "Standard")<br/>    account_replication_type        = optional(string, "ZRS")<br/>    access_tier                     = optional(string, "Hot")<br/>    index_document                  = optional(string, "index.html")<br/>    error_404_document              = optional(string, "error.html")<br/>    nested_items_public             = optional(bool, true)<br/>    public_network_access           = optional(bool, true)<br/>    allow_nested_items_to_be_public = optional(bool, true)<br/>    threat_protection_enabled       = optional(bool, false)<br/>    origin_group                    = optional(string)<br/>  })</pre> | `{}` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to all resources | `map(string)` | `{}` | no |
| <a name="input_tenant_id"></a> [tenant\_id](#input\_tenant\_id) | Tenant ID for Key Vault access (required if using CustomerCertificate domains) | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_custom_domain_ids"></a> [custom\_domain\_ids](#output\_custom\_domain\_ids) | Map of custom domain (hostname) => CDN Front Door custom domain ID |
| <a name="output_endpoint_hostnames"></a> [endpoint\_hostnames](#output\_endpoint\_hostnames) | Map of endpoint key => default CDN Front Door hostname (e.g. to create CNAME/ALIAS records) |
| <a name="output_endpoint_ids"></a> [endpoint\_ids](#output\_endpoint\_ids) | Map of endpoint key => CDN Front Door endpoint ID |
| <a name="output_origin_group_ids"></a> [origin\_group\_ids](#output\_origin\_group\_ids) | Map of origin\_group key => CDN Front Door origin group ID |
| <a name="output_origin_ids"></a> [origin\_ids](#output\_origin\_ids) | Map of origin key => CDN Front Door origin ID (only origins declared in var.origins, excludes the auto-injected storage origin) |
| <a name="output_profile_id"></a> [profile\_id](#output\_profile\_id) | ID of the CDN Front Door profile |
| <a name="output_profile_identity_principal_id"></a> [profile\_identity\_principal\_id](#output\_profile\_identity\_principal\_id) | Principal ID of the profile's system-assigned managed identity (used for Key Vault access) |
| <a name="output_profile_name"></a> [profile\_name](#output\_profile\_name) | Name of the CDN Front Door profile |
| <a name="output_route_ids"></a> [route\_ids](#output\_route\_ids) | Map of route key => CDN Front Door route ID |
| <a name="output_ruleset_ids"></a> [ruleset\_ids](#output\_ruleset\_ids) | Map of ruleset key => CDN Front Door rule set ID |
| <a name="output_storage_account_id"></a> [storage\_account\_id](#output\_storage\_account\_id) | ID of the static-website storage account, if enabled |
| <a name="output_storage_account_name"></a> [storage\_account\_name](#output\_storage\_account\_name) | Name of the static-website storage account, if enabled |
| <a name="output_storage_account_primary_web_host"></a> [storage\_account\_primary\_web\_host](#output\_storage\_account\_primary\_web\_host) | Primary static website host of the storage account, if enabled (the host wired as CDN origin) |
<!-- END_TF_DOCS -->
