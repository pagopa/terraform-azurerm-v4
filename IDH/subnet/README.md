# Postgres Flexible Server

Module that allows the creation of a postgres flexible.

## Production Ready

> See how to use in production: <https://pagopa.atlassian.net/wiki/spaces/DEVOPS/pages/484474896/Postgres+Flexible>

## Architecture

![architecture](./docs/module-arch.drawio.png)

## Connection to DB

* if **pgbounce** is enabled: the port is 6432, otherwise: 5432

## Limits and constraints

* **HA** and **pg bouncer** is not avaible for `B series` machines

## Customer managed key

It's now possible to use a `Customer managed key`. To achieve this result you need to set:

```yaml
customer_managed_key_enabled      = true (default = false)
```

Please have a look at the example in the `tests` folder to understand how to proceed and see a working example.

## Metrics

By default the module has his own metrics, but if you want to override it you can use the parameter `custom_metric_alerts` with this example structure:

```hcl
variable "pgflex_public_metric_alerts" {
  description = <<EOD
  Map of name = criteria objects
  EOD

  type = map(object({
    # criteria.*.aggregation to be one of [Average Count Minimum Maximum Total]
    aggregation = string
    # "Insights.Container/pods" "Insights.Container/nodes"
    metric_namespace = string
    metric_name      = string
    # criteria.0.operator to be one of [Equals NotEquals GreaterThan GreaterThanOrEqual LessThan LessThanOrEqual]
    operator  = string
    threshold = number
    # Possible values are PT1M, PT5M, PT15M, PT30M and PT1H
    frequency = string
    # Possible values are PT1M, PT5M, PT15M, PT30M, PT1H, PT6H, PT12H and P1D.
    window_size = string
    # severity: The severity of this Metric Alert. Possible values are 0, 1, 2, 3 and 4. Defaults to 3. Lower is worst
    severity = number
  }))

  default = {
    cpu_percent = {
      frequency        = "PT1M"
      window_size      = "PT5M"
      metric_namespace = "Microsoft.DBforPostgreSQL/flexibleServers"
      aggregation      = "Average"
      metric_name      = "cpu_percent"
      operator         = "GreaterThan"
      threshold        = 80
      severity = 2
    }
  }
}
```

## How to use it (Public mode & Private mode)

```hcl
  # KV secrets flex server
  data "azurerm_key_vault_secret" "pgres_flex_admin_login" {
    name         = "pgres-flex-admin-login"
    key_vault_id = data.azurerm_key_vault.kv.id
  }

  data "azurerm_key_vault_secret" "pgres_flex_admin_pwd" {
    name         = "pgres-flex-admin-pwd"
    key_vault_id = data.azurerm_key_vault.kv.id
  }

  #------------------------------------------------
  resource "azurerm_resource_group" "postgres_dbs" {
    name     = "${local.program}-postgres-dbs-rg"
    location = var.location

    tags = var.tags
  }

  # Postgres Flexible Server subnet
  module "postgres_flexible_snet" {
    source                                    = "git::https://github.com/pagopa/terraform-azurerm-v3.git//subnet?ref=v8.8.0"
    name                                      = "${local.program}-pgres-flexible-snet"
    address_prefixes                          = var.cidr_subnet_flex_dbms
    resource_group_name                       = data.azurerm_resource_group.rg_vnet.name
    virtual_network_name                      = data.azurerm_virtual_network.vnet.name
    service_endpoints                         = ["Microsoft.Storage"]
    private_endpoint_network_policies_enabled = true

    delegation = {
      name = "delegation"
      service_delegation = {
        name = "Microsoft.DBforPostgreSQL/flexibleServers"
        actions = [
          "Microsoft.Network/virtualNetworks/subnets/join/action",
        ]
      }
    }
  }

  # DNS private single server
  resource "azurerm_private_dns_zone" "privatelink_postgres_database_azure_com" {

    name                = "privatelink.postgres.database.azure.com"
    resource_group_name = data.azurerm_resource_group.rg_vnet.name

    tags = var.tags
  }

  resource "azurerm_private_dns_zone_virtual_network_link" "privatelink_postgres_database_azure_com_vnet" {

    name                  = "${local.program}-pg-flex-link"
    private_dns_zone_name = azurerm_private_dns_zone.privatelink_postgres_database_azure_com.name

    resource_group_name = data.azurerm_resource_group.rg_vnet.name
    virtual_network_id  = data.azurerm_virtual_network.vnet.id

    registration_enabled = false

    tags = var.tags
  }

  # https://docs.microsoft.com/en-us/azure/postgresql/flexible-server/concepts-compare-single-server-flexible-server
  module "postgres_flexible_server_private" {

    count = var.pgflex_private_config.enabled ? 1 : 0

    source = "git::https://github.com/pagopa/terraform-azurerm-v3.git//postgres_flexible_server?ref=v8.8.0"

    name                = "${local.program}-private-pgflex"
    location            = azurerm_resource_group.postgres_dbs.location
    resource_group_name = azurerm_resource_group.postgres_dbs.name

    ### Network
    private_endpoint_enabled = false
    private_dns_zone_id      = azurerm_private_dns_zone.privatelink_postgres_database_azure_com.id
    delegated_subnet_id      = module.postgres_flexible_snet.id

    ### Admin
    administrator_login    = data.azurerm_key_vault_secret.pgres_flex_admin_login.value
    administrator_password = data.azurerm_key_vault_secret.pgres_flex_admin_pwd.value

    sku_name   = "B_Standard_B1ms"
    db_version = "13"
    # Possible values are 32768, 65536, 131072, 262144, 524288, 1048576,
    # 2097152, 4194304, 8388608, 16777216, and 33554432.
    storage_mb = 32768

    ### zones & HA
    zone                      = 1
    high_availability_enabled = false
    standby_availability_zone = 3

    maintenance_window_config = {
      day_of_week  = 0
      start_hour   = 2
      start_minute = 0
    }

    ### backup
    backup_retention_days        = 7
    geo_redundant_backup_enabled = false

    pgbouncer_enabled = false

    tags = var.tags

    custom_metric_alerts = var.pgflex_public_metric_alerts
    alerts_enabled       = true

    diagnostic_settings_enabled               = true
    log_analytics_workspace_id                = data.azurerm_log_analytics_workspace.log_analytics_workspace.id
    diagnostic_setting_destination_storage_id = data.azurerm_storage_account.security_monitoring_storage.id

    depends_on = [azurerm_private_dns_zone_virtual_network_link.privatelink_postgres_database_azure_com_vnet]

  }

  #
  # Public Flexible
  #

  # https://docs.microsoft.com/en-us/azure/postgresql/flexible-server/concepts-compare-single-server-flexible-server
  module "postgres_flexible_server_public" {

    count = var.pgflex_public_config.enabled ? 1 : 0

    source = "git::https://github.com/pagopa/terraform-azurerm-v3.git//postgres_flexible_server?ref=v8.8.0"

    name                = "${local.program}-public-pgflex"
    location            = azurerm_resource_group.postgres_dbs.location
    resource_group_name = azurerm_resource_group.postgres_dbs.name

    administrator_login    = data.azurerm_key_vault_secret.pgres_flex_admin_login.value
    administrator_password = data.azurerm_key_vault_secret.pgres_flex_admin_pwd.value

    sku_name   = "B_Standard_B1ms"
    db_version = "13"
    # Possible values are 32768, 65536, 131072, 262144, 524288, 1048576,
    # 2097152, 4194304, 8388608, 16777216, and 33554432.
    storage_mb                   = 32768
    zone                         = 1
    backup_retention_days        = 7
    geo_redundant_backup_enabled = false

    high_availability_enabled = false
    private_endpoint_enabled  = false
    pgbouncer_enabled         = false

    tags = var.tags

    custom_metric_alerts = var.pgflex_public_metric_alerts
    alerts_enabled       = true

    diagnostic_settings_enabled               = true
    log_analytics_workspace_id                = data.azurerm_log_analytics_workspace.log_analytics_workspace.id
    diagnostic_setting_destination_storage_id = data.azurerm_storage_account.security_monitoring_storage.id

  }
```

It is also possible to register the newly created server into a private dn zone, so that your apps can connect to the database using a common name that will not change even in case of a disaster and the failover to a replica with a different FQDN
in the example below all the core parameters for postgres are omitted for simplicity

```hcl

# somehere else in project files, probably in core module
resource "azurerm_private_dns_zone" "private_db_dns_zone" {
  count = var.geo_replica_enabled ? 1 : 0
  name                = "${var.env_short}.internal.postgresql.pagopa.it"
  resource_group_name = data.azurerm_resource_group.data_rg.name

  tags = var.tags
}
 
############################

module "postgres_flexible_server_private" {

    count = var.pgflex_private_config.enabled ? 1 : 0

    source = "git::https://github.com/pagopa/terraform-azurerm-v3.git//postgres_flexible_server?ref=v8.8.0"

    name                = "${local.program}-private-pgflex"
    location            = azurerm_resource_group.postgres_dbs.location
    resource_group_name = azurerm_resource_group.postgres_dbs.name

    [...]
  
    # private dns zone registration
    private_dns_registration                  = true
    private_dns_zone_name                     = "${var.env_short}.internal.postgresql.pagopa.it"
    private_dns_zone_rg_name                  = data.azurerm_resource_group.data_rg.name
    private_dns_record_cname                  = "my-service-db"

  }


```

## Migration from v2

### 🔥 re-import the resource azurerm_monitor_diagnostic_setting

Is possible that you need to re-import this resource

```ts
module.postgres_flexible_server_public[0].azurerm_monitor_diagnostic_setting.this[0]
```

See [Generic resorce migration](../docs/MIGRATION_GUIDE_GENERIC_RESOURCES.md)

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
| <a name="module_idh_loader"></a> [idh\_loader](#module\_idh\_loader) | ../00_idh_loader | n/a |
| <a name="module_subnet"></a> [subnet](#module\_subnet) | ../../subnet | n/a |

## Resources

| Name | Type |
|------|------|
| [terraform_data.subnet_cidr](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |
| [azurerm_subnet.subnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/subnet) | data source |
| [azurerm_virtual_network.vnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/virtual_network) | data source |
| [external_external.subnet_cidr](https://registry.terraform.io/providers/hashicorp/external/latest/docs/data-sources/external) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_env"></a> [env](#input\_env) | n/a | `string` | n/a | yes |
| <a name="input_idh_resource"></a> [idh\_resource](#input\_idh\_resource) | (Required) The name od IDH resource key to be created. | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | (Required) The name which should be used for this PostgreSQL Flexible Server. Changing this forces a new PostgreSQL Flexible Server to be created. | `string` | n/a | yes |
| <a name="input_prefix"></a> [prefix](#input\_prefix) | n/a | `string` | n/a | yes |
| <a name="input_private_endpoint_network_policies"></a> [private\_endpoint\_network\_policies](#input\_private\_endpoint\_network\_policies) | (Optional) Enable or Disable network policies for the private endpoint on the subnet. Possible values are Disabled, Enabled, NetworkSecurityGroupEnabled and RouteTableEnabled. Defaults to Disabled. | `string` | `"Disabled"` | no |
| <a name="input_private_link_service_network_policies_enabled"></a> [private\_link\_service\_network\_policies\_enabled](#input\_private\_link\_service\_network\_policies\_enabled) | (Optional) Enable or Disable network policies for the private link service on the subnet. Setting this to true will Enable the policy and setting this to false will Disable the policy. Defaults to true. | `bool` | `true` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | (Required) The name of the Resource Group where the PostgreSQL Flexible Server should exist. | `string` | n/a | yes |
| <a name="input_service_endpoints"></a> [service\_endpoints](#input\_service\_endpoints) | (Optional) The list of Service endpoints to associate with the subnet. Possible values include: Microsoft.AzureActiveDirectory, Microsoft.AzureCosmosDB, Microsoft.ContainerRegistry, Microsoft.EventHub, Microsoft.KeyVault, Microsoft.ServiceBus, Microsoft.Sql, Microsoft.Storage and Microsoft.Web. | `list(string)` | `[]` | no |
| <a name="input_virtual_network_name"></a> [virtual\_network\_name](#input\_virtual\_network\_name) | n/a | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_address_prefixes"></a> [address\_prefixes](#output\_address\_prefixes) | n/a |
| <a name="output_id"></a> [id](#output\_id) | n/a |
| <a name="output_name"></a> [name](#output\_name) | n/a |
| <a name="output_resource_group_name"></a> [resource\_group\_name](#output\_resource\_group\_name) | n/a |
| <a name="output_subnet_id"></a> [subnet\_id](#output\_subnet\_id) | n/a |
| <a name="output_subnet_name"></a> [subnet\_name](#output\_subnet\_name) | n/a |
| <a name="output_virtual_network_name"></a> [virtual\_network\_name](#output\_virtual\_network\_name) | n/a |
<!-- END_TF_DOCS -->
