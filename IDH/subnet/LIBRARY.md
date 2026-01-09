# IDH subnet Resources

## All
| Product  | Environment | Tier | Description |
|:-------------:|:----------------:|:---------:|:----------------|
| All | All |  aks_overlay | Prefix length: 24, delegation: -, embedded nsg allowed: -, pe network policy: Disabled |
| All | All |  app_service | Prefix length: 27, delegation: Microsoft.Web/serverFarms, embedded nsg allowed: -, pe network policy: Disabled |
| All | All |  container_app_environment | Prefix length: 23, delegation: Microsoft.App/environments, embedded nsg allowed: -, pe network policy: Disabled |
| All | All |  gateway | Prefix length: 24, delegation: -, embedded nsg allowed: -, pe network policy: Disabled |
| All | All |  postgres_flexible | Prefix length: 28, delegation: Microsoft.DBforPostgreSQL/flexibleServers, embedded nsg allowed: True, pe network policy: Disabled |
| All | All |  private_endpoint | Prefix length: 26, delegation: -, embedded nsg allowed: -, pe network policy: Enabled |
| All | All |  slash28_privatelink_false | Prefix length: 28, delegation: -, embedded nsg allowed: -, pe network policy: Disabled |
| All | All |  slash28_privatelink_true | Prefix length: 28, delegation: -, embedded nsg allowed: -, pe network policy: Disabled |
## cstar
| Product  | Environment | Tier | Description |
|:-------------:|:----------------:|:---------:|:----------------|
|---|---|---|---|
| cstar | dev |  container_app_environment_27 | Prefix length: 27, delegation: Microsoft.App/environments, embedded nsg allowed: -, pe network policy: Disabled |
|---|---|---|---|
| cstar | prod |  container_app_environment_27 | Prefix length: 27, delegation: Microsoft.App/environments, embedded nsg allowed: -, pe network policy: Disabled |
|---|---|---|---|
| cstar | uat |  container_app_environment_27 | Prefix length: 27, delegation: Microsoft.App/environments, embedded nsg allowed: -, pe network policy: Disabled |
