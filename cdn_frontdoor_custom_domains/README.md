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

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_cdn_frontdoor_custom_domain.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_custom_domain) | resource |
| [azurerm_cdn_frontdoor_custom_domain_association.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_custom_domain_association) | resource |
| [azurerm_cdn_frontdoor_secret.cert_secrets](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_secret) | resource |
| [azurerm_dns_a_record.apex](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/dns_a_record) | resource |
| [azurerm_dns_cname_record.subdomain](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/dns_cname_record) | resource |
| [azurerm_dns_txt_record.validation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/dns_txt_record) | resource |
| [azurerm_key_vault_access_policy.afd_policy](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_access_policy) | resource |
| [azurerm_cdn_frontdoor_endpoint.cdn_endpoint](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/cdn_frontdoor_endpoint) | data source |
| [azurerm_cdn_frontdoor_profile.cdn](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/cdn_frontdoor_profile) | data source |
| [azurerm_dns_zone.zones](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/dns_zone) | data source |
| [azurerm_key_vault_certificate.certs](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/key_vault_certificate) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cdn_prefix_name"></a> [cdn\_prefix\_name](#input\_cdn\_prefix\_name) | Prefix for Front Door naming (e.g. myapp-prod). | `string` | n/a | yes |
| <a name="input_cdn_route_id"></a> [cdn\_route\_id](#input\_cdn\_route\_id) | ID della route Front Door a cui associare tutti i custom domains. | `string` | n/a | yes |
| <a name="input_custom_domains"></a> [custom\_domains](#input\_custom\_domains) | List of custom domains with DNS zone and per-domain control for DNS records. | <pre>list(object({<br/>    domain_name             = string<br/>    dns_name                = string<br/>    dns_resource_group_name = string<br/>    ttl                     = optional(number, 3600)<br/>    enable_dns_records      = optional(bool, true)<br/>  }))</pre> | n/a | yes |
| <a name="input_keyvault_id"></a> [keyvault\_id](#input\_keyvault\_id) | Key Vault ID containing certificates. | `string` | n/a | yes |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Resource group of the Front Door profile. | `string` | n/a | yes |
| <a name="input_tenant_id"></a> [tenant\_id](#input\_tenant\_id) | Tenant ID. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_custom_domain_hostnames"></a> [custom\_domain\_hostnames](#output\_custom\_domain\_hostnames) | Lista degli hostnames configurati su Front Door. |
| <a name="output_custom_domain_validation_tokens"></a> [custom\_domain\_validation\_tokens](#output\_custom\_domain\_validation\_tokens) | Mappa hostname → validation token per TXT record. |
| <a name="output_dns_a_records"></a> [dns\_a\_records](#output\_dns\_a\_records) | Mappa degli A records creati (solo domini apex con enable\_dns\_records=true). |
| <a name="output_dns_cname_records"></a> [dns\_cname\_records](#output\_dns\_cname\_records) | Mappa dei CNAME records creati (solo subdomains con enable\_dns\_records=true). |
| <a name="output_dns_txt_records"></a> [dns\_txt\_records](#output\_dns\_txt\_records) | Mappa degli TXT records creati per validazione dominio. |
| <a name="output_endpoint_id"></a> [endpoint\_id](#output\_endpoint\_id) | n/a |
| <a name="output_endpoint_name"></a> [endpoint\_name](#output\_endpoint\_name) | n/a |
| <a name="output_fqdn"></a> [fqdn](#output\_fqdn) | n/a |
| <a name="output_hostname"></a> [hostname](#output\_hostname) | n/a |
| <a name="output_id"></a> [id](#output\_id) | Deprecated, use endpoint\_id instead. |
| <a name="output_profile_id"></a> [profile\_id](#output\_profile\_id) | n/a |
| <a name="output_profile_name"></a> [profile\_name](#output\_profile\_name) | n/a |
<!-- END_TF_DOCS -->
