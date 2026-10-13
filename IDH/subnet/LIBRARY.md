# IDH subnet Resources

## All
| Product  | Environment | Tier | Deprecated | Description |
|:-------------:|:----------------:|:---------:|:---------:|:----------------|
| All | All |  aks_overlay | No | Prefix length: 24, delegation: -, embedded nsg allowed: -, pe network policy: Disabled |
| All | All |  app_service | No | Prefix length: 27, delegation: Microsoft.Web/serverFarms, embedded nsg allowed: -, pe network policy: Disabled |
| All | All |  container_app_environment | No | Prefix length: 23, delegation: Microsoft.App/environments, embedded nsg allowed: -, pe network policy: Disabled |
| All | All |  gateway | No | Prefix length: 24, delegation: -, embedded nsg allowed: -, pe network policy: Disabled |
| All | All |  postgres_flexible | No | Prefix length: 28, delegation: Microsoft.DBforPostgreSQL/flexibleServers, embedded nsg allowed: True, pe network policy: Disabled |
| All | All |  ~~private_endpoint~~ | **Yes** | Prefix length: 26, delegation: -, embedded nsg allowed: -, pe network policy: Enabled |
| All | All |  slash28_privatelink_false | No | Prefix length: 28, delegation: -, embedded nsg allowed: -, pe network policy: Disabled |
| All | All |  slash28_privatelink_true | No | Prefix length: 28, delegation: -, embedded nsg allowed: -, pe network policy: Disabled |
## cstar
| Product  | Environment | Tier | Deprecated | Description |
|:-------------:|:----------------:|:---------:|:---------:|:----------------|
|---|---|---|---|
| cstar | dev |  container_app_environment_27 | No | Prefix length: 27, delegation: Microsoft.App/environments, embedded nsg allowed: -, pe network policy: Disabled |
|---|---|---|---|
| cstar | prod |  container_app_environment_27 | No | Prefix length: 27, delegation: Microsoft.App/environments, embedded nsg allowed: -, pe network policy: Disabled |
|---|---|---|---|
| cstar | uat |  container_app_environment_27 | No | Prefix length: 27, delegation: Microsoft.App/environments, embedded nsg allowed: -, pe network policy: Disabled |
