# IDH postgres_flexible_server resources
|Platform| Environment| Name | Description | 
|------|---------|----|---|
|pagopa|prod|pgflex2| Postgres v16, storage: 131072 MB, geo_redundant_backup: True, private dns registration: True, ha: True, public: False geo replication allowed: True, pg bouncer: True
 |
|pagopa|prod|pgflex4| Postgres v16, storage: 131072 MB, geo_redundant_backup: True, private dns registration: True, ha: False, public: False geo replication allowed: True, pg bouncer: True
 |
|pagopa|prod|pgflex8| Postgres v16, storage: 131072 MB, geo_redundant_backup: True, private dns registration: True, ha: True, public: False geo replication allowed: True, pg bouncer: True
 |
|pagopa|prod|pgflex16| Postgres v16, storage: 131072 MB, geo_redundant_backup: True, private dns registration: True, ha: True, public: False geo replication allowed: True, pg bouncer: True
 |
|pagopa|uat|pgflex2| Postgres v16, storage: 131072 MB, geo_redundant_backup: False, private dns registration: True, ha: False, public: False geo replication allowed: False, pg bouncer: True
 |
|pagopa|uat|pgflex4| Postgres v16, storage: 131072 MB, geo_redundant_backup: False, private dns registration: True, ha: False, public: False geo replication allowed: False, pg bouncer: True
 |
|pagopa|uat|pgflex8| Postgres v16, storage: 131072 MB, geo_redundant_backup: False, private dns registration: True, ha: False, public: False geo replication allowed: False, pg bouncer: True
 |
|pagopa|dev|pgflex2| Postgres v16, storage: 32768 MB, geo_redundant_backup: False, private dns registration: True, ha: False, public: True geo replication allowed: False, pg bouncer: True
 |
|pagopa|dev|pgflex4| Postgres v16, storage: 32768 MB, geo_redundant_backup: False, private dns registration: True, ha: False, public: True geo replication allowed: False, pg bouncer: True
 |
