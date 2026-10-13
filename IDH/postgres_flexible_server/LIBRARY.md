# IDH postgres_flexible_server Resources

## cstar
| Product  | Environment | Tier | Deprecated | Description |
|:-------------:|:----------------:|:---------:|:---------:|:----------------|
| cstar | dev |  pg_burst_flex2 | No | Postgres v16, sku: B_Standard_B2s, storage: 32768 MB, geo redundant backup (if available): False, private dns registration: True, ha: False, public: False, geo replication allowed: False, pg bouncer: False |
| cstar | dev |  pgflex2 | No | Postgres v16, sku: GP_Standard_D2ds_v5, storage: 32768 MB, geo redundant backup (if available): False, private dns registration: True, ha: False, public: False, geo replication allowed: False, pg bouncer: True |
| cstar | dev |  pgflex4 | No | Postgres v16, sku: GP_Standard_D4ds_v5, storage: 32768 MB, geo redundant backup (if available): False, private dns registration: True, ha: False, public: False, geo replication allowed: False, pg bouncer: True |
|---|---|---|---|
| cstar | prod |  pgflex16 | No | Postgres v16, sku: GP_Standard_D16ds_v5, storage: 32768 MB, geo redundant backup (if available): True, private dns registration: True, ha: True, public: False, geo replication allowed: True, pg bouncer: True |
| cstar | prod |  pgflex2 | No | Postgres v16, sku: GP_Standard_D2ds_v5, storage: 32768 MB, geo redundant backup (if available): True, private dns registration: True, ha: True, public: False, geo replication allowed: True, pg bouncer: True |
| cstar | prod |  pgflex4 | No | Postgres v16, sku: GP_Standard_D4ds_v5, storage: 32768 MB, geo redundant backup (if available): True, private dns registration: True, ha: True, public: False, geo replication allowed: True, pg bouncer: True |
| cstar | prod |  pgflex8 | No | Postgres v16, sku: GP_Standard_D8ds_v5, storage: 32768 MB, geo redundant backup (if available): True, private dns registration: True, ha: True, public: False, geo replication allowed: True, pg bouncer: True |
|---|---|---|---|
| cstar | uat |  pgflex2 | No | Postgres v16, sku: GP_Standard_D2ds_v5, storage: 32768 MB, geo redundant backup (if available): False, private dns registration: True, ha: False, public: False, geo replication allowed: False, pg bouncer: True |
| cstar | uat |  pgflex4 | No | Postgres v16, sku: GP_Standard_D4ds_v5, storage: 32768 MB, geo redundant backup (if available): False, private dns registration: True, ha: False, public: False, geo replication allowed: False, pg bouncer: True |
| cstar | uat |  pgflex8 | No | Postgres v16, sku: GP_Standard_D8ds_v5, storage: 32768 MB, geo redundant backup (if available): False, private dns registration: True, ha: False, public: False, geo replication allowed: False, pg bouncer: True |
## dvopla
| Product  | Environment | Tier | Deprecated | Description |
|:-------------:|:----------------:|:---------:|:---------:|:----------------|
| dvopla | dev |  pgflex2 | No | Postgres v16, sku: GP_Standard_D2ds_v5, storage: 32768 MB, geo redundant backup (if available): False, private dns registration: True, ha: False, public: True, geo replication allowed: False, pg bouncer: True |
| dvopla | dev |  pgflex4 | No | Postgres v16, sku: GP_Standard_D4ds_v5, storage: 32768 MB, geo redundant backup (if available): False, private dns registration: True, ha: False, public: True, geo replication allowed: False, pg bouncer: True |
## pagopa
| Product  | Environment | Tier | Deprecated | Description |
|:-------------:|:----------------:|:---------:|:---------:|:----------------|
| pagopa | dev |  pgflex2 | No | Postgres v16, sku: GP_Standard_D2ds_v5, storage: 32768 MB, geo redundant backup (if available): False, private dns registration: True, ha: False, public: False, geo replication allowed: False, pg bouncer: True |
| pagopa | dev |  ~~pgflex2_public~~ | **Yes** | Postgres v16, sku: GP_Standard_D2ds_v5, storage: 32768 MB, geo redundant backup (if available): False, private dns registration: True, ha: False, public: True, geo replication allowed: False, pg bouncer: True |
| pagopa | dev |  pgflex4 | No | Postgres v16, sku: GP_Standard_D4ds_v5, storage: 32768 MB, geo redundant backup (if available): False, private dns registration: True, ha: False, public: False, geo replication allowed: False, pg bouncer: True |
| pagopa | dev |  ~~pgflex4_public~~ | **Yes** | Postgres v16, sku: GP_Standard_D4ds_v5, storage: 32768 MB, geo redundant backup (if available): False, private dns registration: True, ha: False, public: True, geo replication allowed: False, pg bouncer: True |
|---|---|---|---|
| pagopa | prod |  pgflex16 | No | Postgres v16, sku: GP_Standard_D16ds_v5, storage: 32768 MB, geo redundant backup (if available): True, private dns registration: True, ha: True, public: False, geo replication allowed: True, pg bouncer: True |
| pagopa | prod |  pgflex2 | No | Postgres v16, sku: GP_Standard_D2ds_v5, storage: 32768 MB, geo redundant backup (if available): True, private dns registration: True, ha: True, public: False, geo replication allowed: True, pg bouncer: True |
| pagopa | prod |  pgflex4 | No | Postgres v16, sku: GP_Standard_D4ds_v5, storage: 32768 MB, geo redundant backup (if available): True, private dns registration: True, ha: True, public: False, geo replication allowed: True, pg bouncer: True |
| pagopa | prod |  pgflex8 | No | Postgres v16, sku: GP_Standard_D8ds_v5, storage: 32768 MB, geo redundant backup (if available): True, private dns registration: True, ha: True, public: False, geo replication allowed: True, pg bouncer: True |
|---|---|---|---|
| pagopa | uat |  pgflex2 | No | Postgres v16, sku: GP_Standard_D2ds_v5, storage: 32768 MB, geo redundant backup (if available): False, private dns registration: True, ha: False, public: False, geo replication allowed: False, pg bouncer: True |
| pagopa | uat |  pgflex4 | No | Postgres v16, sku: GP_Standard_D4ds_v5, storage: 32768 MB, geo redundant backup (if available): False, private dns registration: True, ha: False, public: False, geo replication allowed: False, pg bouncer: True |
| pagopa | uat |  pgflex8 | No | Postgres v16, sku: GP_Standard_D8ds_v5, storage: 32768 MB, geo redundant backup (if available): False, private dns registration: True, ha: False, public: False, geo replication allowed: False, pg bouncer: True |
