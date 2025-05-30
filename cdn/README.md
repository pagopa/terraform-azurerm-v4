# CDN

This module allow the creation of a CDN endpoint and CDN profile

## Architecture

![This is an image](./docs/module-arch.drawio.png)

## Logical breaking changes

* `resource_advanced_threat_protection_enabled` was removed -> use `advanced_threat_protection_enabled`

## How to use it

```ts
### Frontend common resources
resource "azurerm_resource_group" "devopslab_cdn_rg" {
  name     = "${local.project}-cdn-rg"
  location = var.location

  tags = var.tags
}

### Frontend resources
#tfsec:ignore:azure-storage-queue-services-logging-enabled:exp:2022-05-01 # already ignored, maybe a bug in tfsec
module "devopslab_cdn" {
  source = "git::https://github.com/pagopa/terraform-azurerm-v3.git//cdn?ref=v8.8.0"

  name                  = "diego"
  prefix                = local.product
  resource_group_name   = azurerm_resource_group.devopslab_cdn_rg.name
  location              = azurerm_resource_group.devopslab_cdn_rg.location
  hostname              = "cdn-diego-app.devopslab.pagopa.it"
  https_rewrite_enabled = true
  
  log_analytics_workspace_id = data.azurerm_log_analytics_workspace.law.id

  index_document     = "index.html"
  error_404_document = "404.html"

  dns_zone_name                = data.azurerm_dns_zone.public.name
  dns_zone_resource_group_name = data.azurerm_resource_group.rg_vnet_core.name

  keyvault_vault_name          = module.key_vault_domain.name
  keyvault_resource_group_name = azurerm_resource_group.sec_rg_domain.name
  keyvault_subscription_id     = data.azurerm_subscription.current.subscription_id

  querystring_caching_behaviour = "BypassCaching"

  global_delivery_rule = {
    cache_expiration_action       = []
    cache_key_query_string_action = []
    modify_request_header_action  = []

    # HSTS
    modify_response_header_action = [{
      action = "Overwrite"
      name   = "Strict-Transport-Security"
      value  = "max-age=31536000"
      },
      # Content-Security-Policy (in Report mode)
      {
        action = "Append"
        name   = "Content-Security-Policy-Report-Only"
        value  = "script-src 'self' https://www.google.com https://www.gstatic.com; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; worker-src 'none'; font-src 'self' https://fonts.googleapis.com https://fonts.gstatic.com; "
      },
      {
        action = "Append"
        name   = "Content-Security-Policy-Report-Only"
        value  = "img-src 'self' https://assets.cdn.io.italia.it data:; "
      }
    ]
  }

  tags = var.tags
}


```

## Migration from v2

🆕 To use this module you need to use change this variables/arguments:

❌ Don't use this variables:

* `lock_enabled` -> don't use any more, the locks are managed outside into the policies

### Migration results

During the apply there will be 1 changed and 1 destroy related to storage see [storage account](../storage_account/README.md)

<!-- markdownlint-disable -->
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 4 |
| <a name="requirement_null"></a> [null](#requirement\_null) | ~> 3.2 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_cdn_storage_account"></a> [cdn\_storage\_account](#module\_cdn\_storage\_account) | ../storage_account | n/a |

## Resources

| Name | Type |
|------|------|
| [azurerm_cdn_endpoint.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_endpoint) | resource |
| [azurerm_cdn_profile.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_profile) | resource |
| [azurerm_dns_a_record.apex_hostname](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/dns_a_record) | resource |
| [azurerm_dns_cname_record.apex_cdnverify](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/dns_cname_record) | resource |
| [azurerm_dns_cname_record.hostname](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/dns_cname_record) | resource |
| [azurerm_key_vault_access_policy.azure_cdn_frontdoor_policy](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_access_policy) | resource |
| [azurerm_monitor_diagnostic_setting.diagnostic_settings_cdn_profile](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_diagnostic_setting) | resource |
| [null_resource.apex_custom_hostname](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.custom_hostname](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.custom_hostname_kv_certificate](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_advanced_threat_protection_enabled"></a> [advanced\_threat\_protection\_enabled](#input\_advanced\_threat\_protection\_enabled) | n/a | `bool` | `false` | no |
| <a name="input_azuread_service_principal_azure_cdn_frontdoor_id"></a> [azuread\_service\_principal\_azure\_cdn\_frontdoor\_id](#input\_azuread\_service\_principal\_azure\_cdn\_frontdoor\_id) | Azure CDN Front Door Principal ID - Microsoft.AzureFrontDoor-Cdn | `string` | `null` | no |
| <a name="input_cdn_location"></a> [cdn\_location](#input\_cdn\_location) | If the location of the CDN needs to be different from that of the storage account, set this variable to the location where the CDN should be created. For example, cdn\_location = westeurope and location = northitaly | `string` | `null` | no |
| <a name="input_create_dns_record"></a> [create\_dns\_record](#input\_create\_dns\_record) | n/a | `bool` | `true` | no |
| <a name="input_custom_hostname_kv_enabled"></a> [custom\_hostname\_kv\_enabled](#input\_custom\_hostname\_kv\_enabled) | Flag required to enable the association between KV certificate and CDN when the hostname is different from the APEX | `bool` | `false` | no |
| <a name="input_delivery_rule"></a> [delivery\_rule](#input\_delivery\_rule) | n/a | <pre>list(object({<br/>    name  = string<br/>    order = number<br/><br/>    // start conditions<br/>    cookies_conditions = list(object({<br/>      selector         = string<br/>      operator         = string<br/>      match_values     = list(string)<br/>      negate_condition = bool<br/>      transforms       = list(string)<br/>    }))<br/><br/>    device_conditions = list(object({<br/>      operator         = string<br/>      match_values     = string<br/>      negate_condition = bool<br/>    }))<br/><br/>    http_version_conditions = list(object({<br/>      operator         = string<br/>      match_values     = list(string)<br/>      negate_condition = bool<br/>    }))<br/><br/>    post_arg_conditions = list(object({<br/>      selector         = string<br/>      operator         = string<br/>      match_values     = list(string)<br/>      negate_condition = bool<br/>      transforms       = list(string)<br/>    }))<br/><br/>    query_string_conditions = list(object({<br/>      operator         = string<br/>      match_values     = list(string)<br/>      negate_condition = bool<br/>      transforms       = list(string)<br/>    }))<br/><br/>    remote_address_conditions = list(object({<br/>      operator         = string<br/>      match_values     = list(string)<br/>      negate_condition = bool<br/>    }))<br/><br/>    request_body_conditions = list(object({<br/>      operator         = string<br/>      match_values     = list(string)<br/>      negate_condition = bool<br/>      transforms       = list(string)<br/>    }))<br/><br/>    request_header_conditions = list(object({<br/>      selector         = string<br/>      operator         = string<br/>      match_values     = list(string)<br/>      negate_condition = bool<br/>      transforms       = list(string)<br/>    }))<br/><br/>    request_method_conditions = list(object({<br/>      operator         = string<br/>      match_values     = list(string)<br/>      negate_condition = bool<br/>    }))<br/><br/>    request_scheme_conditions = list(object({<br/>      operator         = string<br/>      match_values     = string<br/>      negate_condition = bool<br/>    }))<br/><br/>    request_uri_conditions = list(object({<br/>      operator         = string<br/>      match_values     = list(string)<br/>      negate_condition = bool<br/>      transforms       = list(string)<br/>    }))<br/><br/>    url_file_extension_conditions = list(object({<br/>      operator         = string<br/>      match_values     = list(string)<br/>      negate_condition = bool<br/>      transforms       = list(string)<br/>    }))<br/><br/>    url_file_name_conditions = list(object({<br/>      operator         = string<br/>      match_values     = list(string)<br/>      negate_condition = bool<br/>      transforms       = list(string)<br/>    }))<br/><br/>    url_path_conditions = list(object({<br/>      operator         = string<br/>      match_values     = list(string)<br/>      negate_condition = bool<br/>      transforms       = list(string)<br/>    }))<br/>    // end conditions<br/><br/>    // start actions<br/>    cache_expiration_actions = list(object({<br/>      behavior = string<br/>      duration = string<br/>    }))<br/><br/>    cache_key_query_string_actions = list(object({<br/>      behavior   = string<br/>      parameters = string<br/>    }))<br/><br/>    modify_request_header_actions = list(object({<br/>      action = string<br/>      name   = string<br/>      value  = string<br/>    }))<br/><br/>    modify_response_header_actions = list(object({<br/>      action = string<br/>      name   = string<br/>      value  = string<br/>    }))<br/><br/>    url_redirect_actions = list(object({<br/>      redirect_type = string<br/>      protocol      = string<br/>      hostname      = string<br/>      path          = string<br/>      fragment      = string<br/>      query_string  = string<br/>    }))<br/><br/>    url_rewrite_actions = list(object({<br/>      source_pattern          = string<br/>      destination             = string<br/>      preserve_unmatched_path = string<br/>    }))<br/>    // end actions<br/>  }))</pre> | `[]` | no |
| <a name="input_delivery_rule_redirect"></a> [delivery\_rule\_redirect](#input\_delivery\_rule\_redirect) | n/a | <pre>list(object({<br/>    name         = string<br/>    order        = number<br/>    operator     = string<br/>    match_values = list(string)<br/>    url_redirect_action = object({<br/>      redirect_type = string<br/>      protocol      = string<br/>      hostname      = string<br/>      path          = string<br/>      fragment      = string<br/>      query_string  = string<br/>    })<br/>  }))</pre> | `[]` | no |
| <a name="input_delivery_rule_request_scheme_condition"></a> [delivery\_rule\_request\_scheme\_condition](#input\_delivery\_rule\_request\_scheme\_condition) | n/a | <pre>list(object({<br/>    name         = string<br/>    order        = number<br/>    operator     = string<br/>    match_values = list(string)<br/>    url_redirect_action = object({<br/>      redirect_type = string<br/>      protocol      = string<br/>      hostname      = string<br/>      path          = string<br/>      fragment      = string<br/>      query_string  = string<br/>    })<br/>  }))</pre> | `[]` | no |
| <a name="input_delivery_rule_rewrite"></a> [delivery\_rule\_rewrite](#input\_delivery\_rule\_rewrite) | n/a | <pre>list(object({<br/>    name  = string<br/>    order = number<br/>    conditions = list(object({<br/>      condition_type   = string<br/>      operator         = string<br/>      match_values     = list(string)<br/>      negate_condition = bool<br/>      transforms       = list(string)<br/>    }))<br/>    url_rewrite_action = object({<br/>      source_pattern          = string<br/>      destination             = string<br/>      preserve_unmatched_path = string<br/>    })<br/>  }))</pre> | `[]` | no |
| <a name="input_delivery_rule_url_path_condition_cache_expiration_action"></a> [delivery\_rule\_url\_path\_condition\_cache\_expiration\_action](#input\_delivery\_rule\_url\_path\_condition\_cache\_expiration\_action) | n/a | <pre>list(object({<br/>    name            = string<br/>    order           = number<br/>    operator        = string<br/>    match_values    = list(string)<br/>    behavior        = string<br/>    duration        = string<br/>    response_action = string<br/>    response_name   = string<br/>    response_value  = string<br/>  }))</pre> | `[]` | no |
| <a name="input_dns_zone_name"></a> [dns\_zone\_name](#input\_dns\_zone\_name) | n/a | `string` | n/a | yes |
| <a name="input_dns_zone_resource_group_name"></a> [dns\_zone\_resource\_group\_name](#input\_dns\_zone\_resource\_group\_name) | n/a | `string` | n/a | yes |
| <a name="input_error_404_document"></a> [error\_404\_document](#input\_error\_404\_document) | n/a | `string` | n/a | yes |
| <a name="input_global_delivery_rule"></a> [global\_delivery\_rule](#input\_global\_delivery\_rule) | n/a | <pre>object({<br/>    cache_expiration_action = list(object({<br/>      behavior = string<br/>      duration = string<br/>    }))<br/>    cache_key_query_string_action = list(object({<br/>      behavior   = string<br/>      parameters = string<br/>    }))<br/>    modify_request_header_action = list(object({<br/>      action = string<br/>      name   = string<br/>      value  = string<br/>    }))<br/>    modify_response_header_action = list(object({<br/>      action = string<br/>      name   = string<br/>      value  = string<br/>    }))<br/>  })</pre> | `null` | no |
| <a name="input_hostname"></a> [hostname](#input\_hostname) | n/a | `string` | n/a | yes |
| <a name="input_https_rewrite_enabled"></a> [https\_rewrite\_enabled](#input\_https\_rewrite\_enabled) | n/a | `bool` | `true` | no |
| <a name="input_index_document"></a> [index\_document](#input\_index\_document) | n/a | `string` | n/a | yes |
| <a name="input_keyvault_id"></a> [keyvault\_id](#input\_keyvault\_id) | Key vault id | `string` | `null` | no |
| <a name="input_keyvault_resource_group_name"></a> [keyvault\_resource\_group\_name](#input\_keyvault\_resource\_group\_name) | Key vault resource group name | `string` | n/a | yes |
| <a name="input_keyvault_subscription_id"></a> [keyvault\_subscription\_id](#input\_keyvault\_subscription\_id) | Key vault subscription id | `string` | n/a | yes |
| <a name="input_keyvault_vault_name"></a> [keyvault\_vault\_name](#input\_keyvault\_vault\_name) | Key vault name | `string` | n/a | yes |
| <a name="input_location"></a> [location](#input\_location) | n/a | `string` | n/a | yes |
| <a name="input_log_analytics_workspace_id"></a> [log\_analytics\_workspace\_id](#input\_log\_analytics\_workspace\_id) | Log Analytics Workspace id to send logs to | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | n/a | `string` | n/a | yes |
| <a name="input_prefix"></a> [prefix](#input\_prefix) | n/a | `string` | n/a | yes |
| <a name="input_querystring_caching_behaviour"></a> [querystring\_caching\_behaviour](#input\_querystring\_caching\_behaviour) | CDN Configuration | `string` | `"IgnoreQueryString"` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | n/a | `string` | n/a | yes |
| <a name="input_storage_access_tier"></a> [storage\_access\_tier](#input\_storage\_access\_tier) | n/a | `string` | `"Hot"` | no |
| <a name="input_storage_account_kind"></a> [storage\_account\_kind](#input\_storage\_account\_kind) | n/a | `string` | `"StorageV2"` | no |
| <a name="input_storage_account_name"></a> [storage\_account\_name](#input\_storage\_account\_name) | (Optional) The storage account name used by the CDN | `string` | `null` | no |
| <a name="input_storage_account_nested_items_public"></a> [storage\_account\_nested\_items\_public](#input\_storage\_account\_nested\_items\_public) | (Optional) reflects to property 'allow\_nested\_items\_to\_be\_public' on storage account module | `bool` | `true` | no |
| <a name="input_storage_account_replication_type"></a> [storage\_account\_replication\_type](#input\_storage\_account\_replication\_type) | n/a | `string` | `"ZRS"` | no |
| <a name="input_storage_account_tier"></a> [storage\_account\_tier](#input\_storage\_account\_tier) | n/a | `string` | `"Standard"` | no |
| <a name="input_storage_public_network_access_enabled"></a> [storage\_public\_network\_access\_enabled](#input\_storage\_public\_network\_access\_enabled) | Flag to set public public network for storage account | `bool` | `true` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | n/a | `map(string)` | n/a | yes |
| <a name="input_tenant_id"></a> [tenant\_id](#input\_tenant\_id) | n/a | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_endpoint_id"></a> [endpoint\_id](#output\_endpoint\_id) | n/a |
| <a name="output_fqdn"></a> [fqdn](#output\_fqdn) | n/a |
| <a name="output_hostname"></a> [hostname](#output\_hostname) | n/a |
| <a name="output_id"></a> [id](#output\_id) | Deprecated, use endpoint\_id instead. |
| <a name="output_name"></a> [name](#output\_name) | n/a |
| <a name="output_profile_id"></a> [profile\_id](#output\_profile\_id) | n/a |
| <a name="output_storage_id"></a> [storage\_id](#output\_storage\_id) | Storage Name |
| <a name="output_storage_name"></a> [storage\_name](#output\_storage\_name) | n/a |
| <a name="output_storage_primary_access_key"></a> [storage\_primary\_access\_key](#output\_storage\_primary\_access\_key) | n/a |
| <a name="output_storage_primary_blob_connection_string"></a> [storage\_primary\_blob\_connection\_string](#output\_storage\_primary\_blob\_connection\_string) | n/a |
| <a name="output_storage_primary_blob_host"></a> [storage\_primary\_blob\_host](#output\_storage\_primary\_blob\_host) | n/a |
| <a name="output_storage_primary_connection_string"></a> [storage\_primary\_connection\_string](#output\_storage\_primary\_connection\_string) | n/a |
| <a name="output_storage_primary_web_host"></a> [storage\_primary\_web\_host](#output\_storage\_primary\_web\_host) | n/a |
| <a name="output_storage_resource_group_name"></a> [storage\_resource\_group\_name](#output\_storage\_resource\_group\_name) | n/a |
<!-- END_TF_DOCS -->
