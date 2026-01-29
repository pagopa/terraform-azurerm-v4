# Postgres Flexible Server

Module that allows the creation of a postgres flexible based on a library of server configuration.
Also handles:
- Database creation
- Geo-replication and private DNS registration

## IDH resources available

[Here's](./LIBRARY.md) the list of `idh_resources_tiers` available for this module


## How to use it

```hcl
  resource "azurerm_resource_group" "db_rg" {
    name     = "${local.product}-test-rg"
    location = var.location
  
    tags = var.tags
  }
  
  data "azurerm_key_vault_secret" "pgres_flex_admin_login" {
    name         = "db-administrator-login"
    key_vault_id = data.azurerm_key_vault.key_vault.id
  }
  
  data "azurerm_key_vault_secret" "pgres_flex_admin_pwd" {
    name         = "db-administrator-login-password"
    key_vault_id = data.azurerm_key_vault.key_vault.id
  }

  
  resource "azurerm_private_dns_zone" "privatelink_postgres_database_azure_com" {
    name                = "private.postgres.database.azure.com"
    resource_group_name = data.azurerm_resource_group.rg_vnet.name

    tags = var.tags
  }

  module "postgres_flexible_server" {
  source = "./.terraform/modules/__v4__/IDH/postgres_flexible_server"

  name                = "${local.project}-flexible-postgresql-idh"
  location            = azurerm_resource_group.db_rg.location
  resource_group_name = azurerm_resource_group.db_rg.name

  idh_resource_tier = "pgflex2"
  product_name = var.product_name
  env = var.env

  private_dns_zone_id           =  data.azurerm_private_dns_zone.privatelink_postgres_database_azure_com.id 
  embedded_subnet = {
    enabled              = true
    vnet_name            = local.spoke_data_vnet_name
    vnet_rg_name         = local.spoke_data_vnet_resource_group_name
  }
    
  embedded_nsg_configuration = {
    source_address_prefixes      = ["*"]
    source_address_prefixes_name = local.domain
  }

  administrator_login    = data.azurerm_key_vault_secret.pgres_flex_admin_login.value
  administrator_password = data.azurerm_key_vault_secret.pgres_flex_admin_pwd.value


  diagnostic_settings_enabled = var.pgres_flex_params.pgres_flex_diagnostic_settings_enabled
  log_analytics_workspace_id  = data.azurerm_log_analytics_workspace.log_analytics.id

  custom_metric_alerts = var.custom_metric_alerts
  alerts_enabled       = var.pgres_flex_params.alerts_enabled

  alert_action = var.pgres_flex_params.alerts_enabled ? [
    {
      action_group_id    = data.azurerm_monitor_action_group.email.id
      webhook_properties = null
    },
    {
      action_group_id    = data.azurerm_monitor_action_group.slack.id
      webhook_properties = null
    },
    {
      action_group_id    = data.azurerm_monitor_action_group.opsgenie[0].id
      webhook_properties = null
    }
  ] : []

  private_dns_registration = var.postgres_dns_registration_enabled
  private_dns_zone_name    = "${var.env_short}.internal.postgresql.pagopa.it"
  private_dns_zone_rg_name = data.azurerm_resource_group.rg_vnet.name
  private_dns_record_cname = "fdr-db"


  tags = var.tags

  geo_replication = {
    enabled = false
    name = "test-replica"
    subnet_id = module.postgres_flexible_snet.id
    location = "westeurope"
    private_dns_registration_ve = true
  }
    
}

```


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
| <a name="module_idh_loader"></a> [idh\_loader](#module\_idh\_loader) | ../01_idh_loader | n/a |
| <a name="module_pgflex"></a> [pgflex](#module\_pgflex) | ../../postgres_flexible_server | n/a |
| <a name="module_pgflex_replica_snet"></a> [pgflex\_replica\_snet](#module\_pgflex\_replica\_snet) | ../subnet | n/a |
| <a name="module_pgflex_snet"></a> [pgflex\_snet](#module\_pgflex\_snet) | ../subnet | n/a |
| <a name="module_replica"></a> [replica](#module\_replica) | ../../postgres_flexible_server_replica | n/a |

## Resources

| Name | Type |
|------|------|
| [azurerm_postgresql_flexible_server_configuration.azure_extensions](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/postgresql_flexible_server_configuration) | resource |
| [azurerm_postgresql_flexible_server_configuration.max_connections](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/postgresql_flexible_server_configuration) | resource |
| [azurerm_postgresql_flexible_server_configuration.max_worker_process](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/postgresql_flexible_server_configuration) | resource |
| [azurerm_postgresql_flexible_server_configuration.pgbouncer_default_pool_size](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/postgresql_flexible_server_configuration) | resource |
| [azurerm_postgresql_flexible_server_configuration.pgbouncer_ignore_startup_parameters](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/postgresql_flexible_server_configuration) | resource |
| [azurerm_postgresql_flexible_server_configuration.pgbouncer_max_client_conn](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/postgresql_flexible_server_configuration) | resource |
| [azurerm_postgresql_flexible_server_configuration.pgbouncer_min_pool_size](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/postgresql_flexible_server_configuration) | resource |
| [azurerm_postgresql_flexible_server_configuration.shared_preoload_libraries](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/postgresql_flexible_server_configuration) | resource |
| [azurerm_postgresql_flexible_server_configuration.wal_level](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/postgresql_flexible_server_configuration) | resource |
| [azurerm_postgresql_flexible_server_database.database](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/postgresql_flexible_server_database) | resource |
| [azurerm_postgresql_flexible_server_virtual_endpoint.virtual_endpoint](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/postgresql_flexible_server_virtual_endpoint) | resource |
| [azurerm_private_dns_cname_record.cname_record](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_cname_record) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_azure_extensions"></a> [additional\_azure\_extensions](#input\_additional\_azure\_extensions) | (Optional) List of additional azure extensions to be installed on the server | `list(string)` | `[]` | no |
| <a name="input_administrator_login"></a> [administrator\_login](#input\_administrator\_login) | Flexible PostgreSql server administrator\_login | `string` | n/a | yes |
| <a name="input_administrator_password"></a> [administrator\_password](#input\_administrator\_password) | Flexible PostgreSql server administrator\_password | `string` | n/a | yes |
| <a name="input_alert_action"></a> [alert\_action](#input\_alert\_action) | The ID of the Action Group and optional map of custom string properties to include with the post webhook operation. | <pre>set(object(<br/>    {<br/>      action_group_id    = string<br/>      webhook_properties = map(string)<br/>    }<br/>  ))</pre> | `[]` | no |
| <a name="input_auto_grow_enabled"></a> [auto\_grow\_enabled](#input\_auto\_grow\_enabled) | (Optional) Is the storage auto grow for PostgreSQL Flexible Server enabled? Defaults to false | `bool` | `false` | no |
| <a name="input_create_self_inbound_nsg_rule"></a> [create\_self\_inbound\_nsg\_rule](#input\_create\_self\_inbound\_nsg\_rule) | (Optional) Flag the automatic creation of self-inbound security rules. Set to true to allow internal traffic within the same security scope | <pre>object({<br/>    embedded = bool<br/>    custom   = bool<br/>  })</pre> | <pre>{<br/>  "custom": true,<br/>  "embedded": true<br/>}</pre> | no |
| <a name="input_custom_metric_alerts"></a> [custom\_metric\_alerts](#input\_custom\_metric\_alerts) | Map of name = criteria objects | <pre>map(object({<br/>    # criteria.*.aggregation to be one of [Average Count Minimum Maximum Total]<br/>    aggregation = string<br/>    metric_name = string<br/>    # "Insights.Container/pods" "Insights.Container/nodes"<br/>    metric_namespace = string<br/>    # criteria.0.operator to be one of [Equals NotEquals GreaterThan GreaterThanOrEqual LessThan LessThanOrEqual]<br/>    operator  = string<br/>    threshold = number<br/>    # Possible values are PT1M, PT5M, PT15M, PT30M and PT1H<br/>    frequency = string<br/>    # Possible values are PT1M, PT5M, PT15M, PT30M, PT1H, PT6H, PT12H and P1D.<br/>    window_size = string<br/>    # severity: The severity of this Metric Alert. Possible values are 0, 1, 2, 3 and 4. Defaults to 3.<br/>    severity = number<br/>  }))</pre> | `null` | no |
| <a name="input_customer_managed_key_enabled"></a> [customer\_managed\_key\_enabled](#input\_customer\_managed\_key\_enabled) | enable customer\_managed\_key | `bool` | `false` | no |
| <a name="input_customer_managed_key_kv_key_id"></a> [customer\_managed\_key\_kv\_key\_id](#input\_customer\_managed\_key\_kv\_key\_id) | The ID of the Key Vault Key | `string` | `null` | no |
| <a name="input_databases"></a> [databases](#input\_databases) | (Optional) List of database names to be created | `list(string)` | `[]` | no |
| <a name="input_db_version"></a> [db\_version](#input\_db\_version) | (Optional) PostgreSQL version | `string` | `null` | no |
| <a name="input_delegated_subnet_id"></a> [delegated\_subnet\_id](#input\_delegated\_subnet\_id) | (Optional) The ID of the virtual network subnet to create the PostgreSQL Flexible Server. The provided subnet should not have any other resource deployed in it and this subnet will be delegated to the PostgreSQL Flexible Server, if not already delegated. | `string` | `null` | no |
| <a name="input_diagnostic_setting_destination_storage_id"></a> [diagnostic\_setting\_destination\_storage\_id](#input\_diagnostic\_setting\_destination\_storage\_id) | (Optional) The ID of the Storage Account where logs should be sent. Changing this forces a new resource to be created. | `string` | `null` | no |
| <a name="input_diagnostic_settings_enabled"></a> [diagnostic\_settings\_enabled](#input\_diagnostic\_settings\_enabled) | Is diagnostic settings enabled? | `bool` | `true` | no |
| <a name="input_domain"></a> [domain](#input\_domain) | n/a | `string` | n/a | yes |
| <a name="input_embedded_nsg_configuration"></a> [embedded\_nsg\_configuration](#input\_embedded\_nsg\_configuration) | (Optional) List of allowed cidr and name . Follows the format defined in https://github.com/pagopa/terraform-azurerm-v4/tree/main/network_security_group#rule-configuration | <pre>object({<br/>    source_address_prefixes      = list(string)<br/>    source_address_prefixes_name = string ## short name for source_address_prefixes<br/>    create_self_inbound          = bool<br/>  })</pre> | <pre>{<br/>  "create_self_inbound": true,<br/>  "source_address_prefixes": [<br/>    "*"<br/>  ],<br/>  "source_address_prefixes_name": "All"<br/>}</pre> | no |
| <a name="input_embedded_subnet"></a> [embedded\_subnet](#input\_embedded\_subnet) | (Optional) Configuration for creating an embedded Subnet for the PostgreSQL Flexible Server. If 'enabled' is true, 'delegated\_subnet\_id' must be null | <pre>object({<br/>    enabled              = bool<br/>    vnet_name            = optional(string, null)<br/>    vnet_rg_name         = optional(string, null)<br/>    replica_vnet_name    = optional(string, null)<br/>    replica_vnet_rg_name = optional(string, null)<br/>  })</pre> | <pre>{<br/>  "enabled": false,<br/>  "replica_vnet_name": null,<br/>  "replica_vnet_rg_name": null,<br/>  "vnet_name": null,<br/>  "vnet_rg_name": null<br/>}</pre> | no |
| <a name="input_env"></a> [env](#input\_env) | (Required) Environment for which the resource will be created | `string` | n/a | yes |
| <a name="input_geo_replication"></a> [geo\_replication](#input\_geo\_replication) | (Optional) Map of geo replication settings | <pre>object({<br/>    enabled                     = bool<br/>    subnet_id                   = optional(string, null)<br/>    location                    = optional(string, null)<br/>    location_short              = optional(string, null)<br/>    private_dns_registration_ve = optional(bool, false)<br/>  })</pre> | <pre>{<br/>  "enabled": false,<br/>  "location": null,<br/>  "location_short": null,<br/>  "private_dns_registration_ve": false,<br/>  "subnet_id": null<br/>}</pre> | no |
| <a name="input_idh_resource_tier"></a> [idh\_resource\_tier](#input\_idh\_resource\_tier) | (Required) The name od IDH resource key to be created. | `string` | n/a | yes |
| <a name="input_location"></a> [location](#input\_location) | (Required) The Azure Region where the PostgreSQL Flexible Server should exist. | `string` | n/a | yes |
| <a name="input_log_analytics_workspace_id"></a> [log\_analytics\_workspace\_id](#input\_log\_analytics\_workspace\_id) | (Optional) Specifies the ID of a Log Analytics Workspace where Diagnostics Data should be sent. | `string` | `null` | no |
| <a name="input_nsg_flow_log_configuration"></a> [nsg\_flow\_log\_configuration](#input\_nsg\_flow\_log\_configuration) | (Optional) NSG flow log configuration | <pre>object({<br/>    enabled                    = bool<br/>    network_watcher_name       = optional(string, null)<br/>    network_watcher_rg         = optional(string, null)<br/>    storage_account_id         = optional(string, null)<br/>    traffic_analytics_law_name = optional(string, null)<br/>    traffic_analytics_law_rg   = optional(string, null)<br/>  })</pre> | <pre>{<br/>  "enabled": false<br/>}</pre> | no |
| <a name="input_pg_bouncer_enabled"></a> [pg\_bouncer\_enabled](#input\_pg\_bouncer\_enabled) | (Optional) Enable or disable PgBouncer. Defaults to false (Server will be restarted on change!) | `bool` | `null` | no |
| <a name="input_prefix"></a> [prefix](#input\_prefix) | n/a | `string` | n/a | yes |
| <a name="input_primary_user_assigned_identity_id"></a> [primary\_user\_assigned\_identity\_id](#input\_primary\_user\_assigned\_identity\_id) | Manages a User Assigned Identity | `string` | `null` | no |
| <a name="input_private_dns_cname_record_ttl"></a> [private\_dns\_cname\_record\_ttl](#input\_private\_dns\_cname\_record\_ttl) | (Optional) if 'private\_dns\_registration' is true, defines the record TTL | `number` | `300` | no |
| <a name="input_private_dns_record_cname"></a> [private\_dns\_record\_cname](#input\_private\_dns\_record\_cname) | (Optional) if 'private\_dns\_registration' is true, defines the private dns CNAME used to register this server FQDN | `string` | `null` | no |
| <a name="input_private_dns_registration"></a> [private\_dns\_registration](#input\_private\_dns\_registration) | (Optional) If true, creates a cname record for the newly created postgreSQL db fqdn into the provided private dns zone | `bool` | `false` | no |
| <a name="input_private_dns_zone_id"></a> [private\_dns\_zone\_id](#input\_private\_dns\_zone\_id) | (Optional) The ID of the private dns zone to create the PostgreSQL Flexible Server. Changing this forces a new PostgreSQL Flexible Server to be created. | `string` | `null` | no |
| <a name="input_private_dns_zone_name"></a> [private\_dns\_zone\_name](#input\_private\_dns\_zone\_name) | (Optional) if 'private\_dns\_registration' is true, defines the private dns zone name in which the server fqdn should be registered | `string` | `null` | no |
| <a name="input_private_dns_zone_rg_name"></a> [private\_dns\_zone\_rg\_name](#input\_private\_dns\_zone\_rg\_name) | (Optional) if 'private\_dns\_registration' is true, defines the private dns zone resource group name of the dns zone in which the server fqdn should be registered | `string` | `null` | no |
| <a name="input_product_name"></a> [product\_name](#input\_product\_name) | (Required) product\_name used to identify the platform for which the resource will be created | `string` | n/a | yes |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | (Required) The name of the Resource Group where the PostgreSQL Flexible Server should exist. | `string` | n/a | yes |
| <a name="input_storage_mb"></a> [storage\_mb](#input\_storage\_mb) | (Optional) The size of the storage in MB. Changing this forces a new PostgreSQL Flexible Server to be created. | `number` | `null` | no |
| <a name="input_storage_tier"></a> [storage\_tier](#input\_storage\_tier) | (Optional) The storage tier of the PostgreSQL Flexible Server. Possible values are P4, P6, P10, P15,P20, P30,P40, P50,P60, P70 or P80. Default value is dependant on the storage\_mb value. | `string` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | n/a | `map(any)` | n/a | yes |
| <a name="input_zone"></a> [zone](#input\_zone) | (Optional) The Availability Zone in which the PostgreSQL Flexible Server should be located. (1,2,3) | `number` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_administrator_login"></a> [administrator\_login](#output\_administrator\_login) | n/a |
| <a name="output_administrator_password"></a> [administrator\_password](#output\_administrator\_password) | n/a |
| <a name="output_connection_port"></a> [connection\_port](#output\_connection\_port) | n/a |
| <a name="output_fqdn"></a> [fqdn](#output\_fqdn) | n/a |
| <a name="output_id"></a> [id](#output\_id) | n/a |
| <a name="output_name"></a> [name](#output\_name) | n/a |
| <a name="output_public_access_enabled"></a> [public\_access\_enabled](#output\_public\_access\_enabled) | n/a |
| <a name="output_replica_fqdn"></a> [replica\_fqdn](#output\_replica\_fqdn) | n/a |
| <a name="output_replica_id"></a> [replica\_id](#output\_replica\_id) | n/a |
| <a name="output_replica_name"></a> [replica\_name](#output\_replica\_name) | n/a |
| <a name="output_virtual_endpoint_name"></a> [virtual\_endpoint\_name](#output\_virtual\_endpoint\_name) | n/a |
<!-- END_TF_DOCS -->
