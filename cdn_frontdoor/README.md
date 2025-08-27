# CDN Front Door

This module provisions an Azure Front Door (Standard/Premium) profile with an Azure Storage static website as origin. It replaces the legacy `cdn` module based on Azure CDN Classic.
    
## Migration notes

*Removed parameters:*

- `advanced_threat_protection_enabled`
- `keyvault_subscription_id`
- `cdn_location` -> use `var.location` 

*Changed names:*

- `index_document` -> `storage_account_index_document`
- `error_404_document` -> `storage_account_error_404_document`
- `keyvault_resource_group_name` & `keyvault_vault_name` -> `keyvault_id`
- `querystring_caching_behaviour` -> default values now is `IgnoreQueryString
- `delivery_rule_redirect` -> `delivery_rule_redirects` now have a list of nested objects (request_uri_conditions,url_path_conditions, url_redirect_actions) to allow to define multiple conditions for the redirect
  - and have a new parameter `behavior_on_match` that is mandatory now
- `delivery_rules` -> `delivery_custom_rules` 
- `delivery_rule_rewrite` -> `delivery_rule_rewrites`

*Changed structure*

- `global_delivery_rules` -> Now all the actions are plural
  - `cache_expiration_actions`
  - `cache_key_query_string_actions` 
  - `modify_request_header_actions` 
  - `modify_response_header_actions` 
- `delivery_rule_redirects` -> use the new structure
- `delivery_rule_rewrite` -> use the new structure

## Usage

```hcl
module "cdn_frontdoor" {
  source = "../cdn_frontdoor"

  dns_prefix_name    = "myprefix-myapp"
  resource_group_name = azurerm_resource_group.example.name
  location            = "westeurope"

  hostname           = "example.com"
  index_document     = "index.html"
  error_404_document = "error.html"
  tags               = {
    Environment = "dev"
  }
}
```

### Migration from legacy `cdn` module

The snippet below shows how to replace the previous Azure CDN Classic module with this Front Door module:

```hcl
# Public CDN to serve frontend - main domain
module "cdn_idpay_bonuselettrodomestici" {
  source = "./.terraform/modules/__v4__/cdn_frontdoor"

  dns_prefix_name           = "${local.project_weu}-bonus"
  resource_group_name       = data.azurerm_resource_group.idpay_data_rg.name
  location                  = var.location
  cdn_location              = var.location_weu

  hostname                  = local.bonus_dns_zone.name

  # DNS is managed separately for multi-domain setup
  dns_zone_name                = "dummy"
  dns_zone_resource_group_name = "dummy"
  create_dns_record            = false

  storage_account_name             = local.cdn_storage_account_name
  storage_account_replication_type = var.idpay_cdn_storage_account_replication_type
  index_document                   = local.cdn_index_document
  error_404_document               = local.cdn_error_document

  https_rewrite_enabled              = true
  advanced_threat_protection_enabled = var.idpay_cdn_sa_advanced_threat_protection_enabled

  keyvault_resource_group_name = local.idpay_kv_rg_name
  keyvault_subscription_id     = data.azurerm_subscription.current.subscription_id
  keyvault_vault_name          = local.idpay_kv_name

  querystring_caching_behaviour = "BypassCaching"
  log_analytics_workspace_id    = data.azurerm_log_analytics_workspace.core_log_analytics.id

  global_delivery_rule = {
    cache_expiration_action       = []
    cache_key_query_string_action = []
    modify_request_header_action  = []
    modify_response_header_action = local.security_headers
  }

  delivery_rule_rewrite = local.app_delivery_rules
  delivery_rule         = local.additional_delivery_rules

  tags = module.tag_config.tags
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
| <a name="module_cdn_storage_account"></a> [cdn\_storage\_account](#module\_cdn\_storage\_account) | ../storage_account | n/a |

## Resources

| Name | Type |
|------|------|
| [azurerm_cdn_frontdoor_custom_domain.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_custom_domain) | resource |
| [azurerm_cdn_frontdoor_endpoint.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_endpoint) | resource |
| [azurerm_cdn_frontdoor_origin.storage_web_host](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_origin) | resource |
| [azurerm_cdn_frontdoor_origin_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_origin_group) | resource |
| [azurerm_cdn_frontdoor_profile.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_profile) | resource |
| [azurerm_cdn_frontdoor_route.default_route](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_route) | resource |
| [azurerm_cdn_frontdoor_rule.global](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_rule) | resource |
| [azurerm_cdn_frontdoor_rule.redirect](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_rule) | resource |
| [azurerm_cdn_frontdoor_rule.rewrite_only](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_rule) | resource |
| [azurerm_cdn_frontdoor_rule.scheme_redirect](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_rule) | resource |
| [azurerm_cdn_frontdoor_rule.url_path_cache](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_rule) | resource |
| [azurerm_cdn_frontdoor_rule_set.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_rule_set) | resource |
| [azurerm_cdn_frontdoor_secret.cert_secrets](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_secret) | resource |
| [azurerm_dns_a_record.apex](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/dns_a_record) | resource |
| [azurerm_dns_cname_record.subdomain](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/dns_cname_record) | resource |
| [azurerm_dns_txt_record.validation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/dns_txt_record) | resource |
| [azurerm_key_vault_access_policy.afd_policy](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_access_policy) | resource |
| [azurerm_monitor_diagnostic_setting.diagnostic_settings_cdn_profile](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_diagnostic_setting) | resource |
| [azurerm_dns_zone.zones](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/dns_zone) | data source |
| [azurerm_key_vault_certificate.certs](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/key_vault_certificate) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cdn_prefix_name"></a> [cdn\_prefix\_name](#input\_cdn\_prefix\_name) | Prefix used for naming resources (e.g. myprefix-myapp). | `string` | n/a | yes |
| <a name="input_custom_domains"></a> [custom\_domains](#input\_custom\_domains) | List of custom domains. | <pre>list(object({<br/>    domain_name             = string<br/>    dns_name                = string<br/>    dns_resource_group_name = string<br/>    ttl                     = optional(number, 3600)<br/>    enable_dns_records      = optional(bool, true)<br/>  }))</pre> | `[]` | no |
| <a name="input_delivery_rule"></a> [delivery\_rule](#input\_delivery\_rule) | n/a | <pre>list(object({<br/>    name  = string<br/>    order = number<br/><br/>    cookies_conditions            = optional(list(object({ selector = string, operator = string, match_values = list(string), negate_condition = bool, transforms = list(string) })), [])<br/>    device_conditions             = optional(list(object({ operator = string, match_values = string, negate_condition = bool })), [])<br/>    http_version_conditions       = optional(list(object({ operator = string, match_values = list(string), negate_condition = bool })), [])<br/>    post_arg_conditions           = optional(list(object({ selector = string, operator = string, match_values = list(string), negate_condition = bool, transforms = list(string) })), [])<br/>    query_string_conditions       = optional(list(object({ operator = string, match_values = list(string), negate_condition = bool, transforms = list(string) })), [])<br/>    remote_address_conditions     = optional(list(object({ operator = string, match_values = list(string), negate_condition = bool })), [])<br/>    request_body_conditions       = optional(list(object({ operator = string, match_values = list(string), negate_condition = bool, transforms = list(string) })), [])<br/>    request_header_conditions     = optional(list(object({ selector = string, operator = string, match_values = list(string), negate_condition = bool, transforms = list(string) })), [])<br/>    request_method_conditions     = optional(list(object({ operator = string, match_values = list(string), negate_condition = bool })), [])<br/>    request_scheme_conditions     = optional(list(object({ operator = string, match_values = string, negate_condition = bool })), [])<br/>    request_uri_conditions        = optional(list(object({ operator = string, match_values = list(string), negate_condition = bool, transforms = list(string) })), [])<br/>    url_file_extension_conditions = optional(list(object({ operator = string, match_values = list(string), negate_condition = bool, transforms = list(string) })), [])<br/>    url_file_name_conditions      = optional(list(object({ operator = string, match_values = list(string), negate_condition = bool, transforms = list(string) })), [])<br/>    url_path_conditions           = optional(list(object({ operator = string, match_values = list(string), negate_condition = bool, transforms = list(string) })), [])<br/><br/>    cache_expiration_actions       = optional(list(object({ behavior = string, duration = string })), [])<br/>    cache_key_query_string_actions = optional(list(object({ behavior = string, parameters = string })), [])<br/>    modify_request_header_actions  = optional(list(object({ action = string, name = string, value = string })), [])<br/>    modify_response_header_actions = optional(list(object({ action = string, name = string, value = string })), [])<br/>    url_redirect_actions           = optional(list(object({ redirect_type = string, protocol = string, hostname = string, path = string, fragment = string, query_string = string })), [])<br/>    url_rewrite_actions            = optional(list(object({ source_pattern = string, destination = string, preserve_unmatched_path = string })), [])<br/>  }))</pre> | `[]` | no |
| <a name="input_delivery_rule_redirect"></a> [delivery\_rule\_redirect](#input\_delivery\_rule\_redirect) | n/a | <pre>list(object({<br/>    name         = string<br/>    order        = number<br/>    operator     = string<br/>    match_values = list(string)<br/>    url_redirect_action = object({<br/>      redirect_type = string<br/>      protocol      = string<br/>      hostname      = string<br/>      path          = string<br/>      fragment      = string<br/>      query_string  = string<br/>    })<br/>  }))</pre> | `[]` | no |
| <a name="input_delivery_rule_request_scheme_condition"></a> [delivery\_rule\_request\_scheme\_condition](#input\_delivery\_rule\_request\_scheme\_condition) | n/a | <pre>list(object({<br/>    name         = string<br/>    order        = number<br/>    operator     = string<br/>    match_values = list(string)<br/>    url_redirect_action = object({<br/>      redirect_type = string<br/>      protocol      = string<br/>      hostname      = string<br/>      path          = string<br/>      fragment      = string<br/>      query_string  = string<br/>    })<br/>  }))</pre> | `[]` | no |
| <a name="input_delivery_rule_rewrite"></a> [delivery\_rule\_rewrite](#input\_delivery\_rule\_rewrite) | n/a | <pre>list(object({<br/>    name  = string<br/>    order = number<br/>    conditions = list(object({<br/>      condition_type   = string<br/>      operator         = string<br/>      match_values     = list(string)<br/>      negate_condition = bool<br/>      transforms       = list(string)<br/>    }))<br/>    url_rewrite_action = object({<br/>      source_pattern          = string<br/>      destination             = string<br/>      preserve_unmatched_path = string<br/>    })<br/>  }))</pre> | `[]` | no |
| <a name="input_delivery_rule_url_path_condition_cache_expiration_action"></a> [delivery\_rule\_url\_path\_condition\_cache\_expiration\_action](#input\_delivery\_rule\_url\_path\_condition\_cache\_expiration\_action) | n/a | <pre>list(object({<br/>    name            = string<br/>    order           = number<br/>    operator        = string<br/>    match_values    = list(string)<br/>    behavior        = string<br/>    duration        = string<br/>    response_action = string<br/>    response_name   = string<br/>    response_value  = string<br/>  }))</pre> | `[]` | no |
| <a name="input_frontdoor_sku_name"></a> [frontdoor\_sku\_name](#input\_frontdoor\_sku\_name) | SKU name for the Azure Front Door profile. | `string` | `"Standard_AzureFrontDoor"` | no |
| <a name="input_global_delivery_rules"></a> [global\_delivery\_rules](#input\_global\_delivery\_rules) | ########################################################### Rules inputs ########################################################### | <pre>list(object({<br/>    order                         = number<br/>    cache_expiration_action       = optional(list(object({ behavior = string, duration = string })), [])<br/>    cache_key_query_string_action = optional(list(object({ behavior = string, parameters = string })), [])<br/>    modify_request_header_action  = optional(list(object({ action = string, name = string, value = string })), [])<br/>    modify_response_header_action = optional(list(object({ action = string, name = string, value = string })), [])<br/>  }))</pre> | `[]` | no |
| <a name="input_https_rewrite_enabled"></a> [https\_rewrite\_enabled](#input\_https\_rewrite\_enabled) | n/a | `bool` | `true` | no |
| <a name="input_keyvault_id"></a> [keyvault\_id](#input\_keyvault\_id) | Key Vault ID containing certificates (used for apex domains). | `string` | `null` | no |
| <a name="input_location"></a> [location](#input\_location) | Primary location (e.g., westeurope). | `string` | n/a | yes |
| <a name="input_log_analytics_workspace_id"></a> [log\_analytics\_workspace\_id](#input\_log\_analytics\_workspace\_id) | Log Analytics Workspace id to send Front Door logs/metrics. | `string` | n/a | yes |
| <a name="input_querystring_caching_behaviour"></a> [querystring\_caching\_behaviour](#input\_querystring\_caching\_behaviour) | ########################################################### Routing and caching defaults ########################################################### | `string` | `"IgnoreQueryString"` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Resource group name where the Front Door profile will be created. | `string` | n/a | yes |
| <a name="input_storage_access_tier"></a> [storage\_access\_tier](#input\_storage\_access\_tier) | n/a | `string` | `"Hot"` | no |
| <a name="input_storage_account_advanced_threat_protection_enabled"></a> [storage\_account\_advanced\_threat\_protection\_enabled](#input\_storage\_account\_advanced\_threat\_protection\_enabled) | n/a | `bool` | `false` | no |
| <a name="input_storage_account_error_404_document"></a> [storage\_account\_error\_404\_document](#input\_storage\_account\_error\_404\_document) | 404 document for static website. | `string` | n/a | yes |
| <a name="input_storage_account_index_document"></a> [storage\_account\_index\_document](#input\_storage\_account\_index\_document) | Index document for static website. | `string` | n/a | yes |
| <a name="input_storage_account_kind"></a> [storage\_account\_kind](#input\_storage\_account\_kind) | n/a | `string` | `"StorageV2"` | no |
| <a name="input_storage_account_name"></a> [storage\_account\_name](#input\_storage\_account\_name) | Optional storage account name; if null, computed from prefix. | `string` | `null` | no |
| <a name="input_storage_account_nested_items_public"></a> [storage\_account\_nested\_items\_public](#input\_storage\_account\_nested\_items\_public) | Reflects 'allow\_nested\_items\_to\_be\_public' on the storage account. | `bool` | `true` | no |
| <a name="input_storage_account_replication_type"></a> [storage\_account\_replication\_type](#input\_storage\_account\_replication\_type) | n/a | `string` | `"ZRS"` | no |
| <a name="input_storage_account_tier"></a> [storage\_account\_tier](#input\_storage\_account\_tier) | n/a | `string` | `"Standard"` | no |
| <a name="input_storage_public_network_access_enabled"></a> [storage\_public\_network\_access\_enabled](#input\_storage\_public\_network\_access\_enabled) | Enable public network for the storage account. | `bool` | `true` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Resource tags. | `map(string)` | n/a | yes |
| <a name="input_tenant_id"></a> [tenant\_id](#input\_tenant\_id) | Tenant ID for KV access policy. | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_endpoint_id"></a> [endpoint\_id](#output\_endpoint\_id) | n/a |
| <a name="output_endpoint_name"></a> [endpoint\_name](#output\_endpoint\_name) | n/a |
| <a name="output_fqdn"></a> [fqdn](#output\_fqdn) | n/a |
| <a name="output_hostname"></a> [hostname](#output\_hostname) | n/a |
| <a name="output_profile_id"></a> [profile\_id](#output\_profile\_id) | n/a |
| <a name="output_profile_name"></a> [profile\_name](#output\_profile\_name) | n/a |
| <a name="output_route_id"></a> [route\_id](#output\_route\_id) | n/a |
| <a name="output_storage_id"></a> [storage\_id](#output\_storage\_id) | Storage outputs |
| <a name="output_storage_name"></a> [storage\_name](#output\_storage\_name) | n/a |
| <a name="output_storage_primary_access_key"></a> [storage\_primary\_access\_key](#output\_storage\_primary\_access\_key) | n/a |
| <a name="output_storage_primary_blob_connection_string"></a> [storage\_primary\_blob\_connection\_string](#output\_storage\_primary\_blob\_connection\_string) | n/a |
| <a name="output_storage_primary_blob_host"></a> [storage\_primary\_blob\_host](#output\_storage\_primary\_blob\_host) | n/a |
| <a name="output_storage_primary_connection_string"></a> [storage\_primary\_connection\_string](#output\_storage\_primary\_connection\_string) | n/a |
| <a name="output_storage_primary_web_host"></a> [storage\_primary\_web\_host](#output\_storage\_primary\_web\_host) | n/a |
| <a name="output_storage_resource_group_name"></a> [storage\_resource\_group\_name](#output\_storage\_resource\_group\_name) | n/a |
<!-- END_TF_DOCS -->
