# IDH storage_account Resources

## cstar
| Product  | Environment | Tier | Deprecated | Description |
|:-------------:|:----------------:|:---------:|:---------:|:----------------|
| cstar | dev |  basic | - | Kind: StorageV2, tier: Standard, min replication: LRS, access tier: Hot, public: False, PiT restore: False, PiT Retention: 0, sftp: False |
| cstar | dev |  basic_public | - | Kind: StorageV2, tier: Standard, min replication: LRS, access tier: Hot, public: True, PiT restore: False, PiT Retention: 0, sftp: False |
|---|---|---|---|
| cstar | prod |  backup30 | - | Kind: StorageV2, tier: Standard, min replication: ZRS, access tier: Hot, public: False, PiT restore: True, PiT Retention: 30, sftp: False |
| cstar | prod |  backup7 | - | Kind: StorageV2, tier: Standard, min replication: ZRS, access tier: Hot, public: False, PiT restore: True, PiT Retention: 7, sftp: False |
| cstar | prod |  backup7_public | - | Kind: StorageV2, tier: Standard, min replication: ZRS, access tier: Hot, public: True, PiT restore: True, PiT Retention: 7, sftp: False |
| cstar | prod |  basic | - | Kind: StorageV2, tier: Standard, min replication: ZRS, access tier: Hot, public: False, PiT restore: True, PiT Retention: 7, sftp: False |
| cstar | prod |  basic_audit | - | Kind: StorageV2, tier: Standard, min replication: ZRS, access tier: Hot, public: False, PiT restore: False, PiT Retention: 0, sftp: False |
| cstar | prod |  basic_public | - | Kind: StorageV2, tier: Standard, min replication: ZRS, access tier: Hot, public: True, PiT restore: True, PiT Retention: 7, sftp: False |
| cstar | prod |  basic_public_no_softdel | - | Kind: StorageV2, tier: Standard, min replication: ZRS, access tier: Hot, public: True, PiT restore: False, PiT Retention: 0, sftp: False |
|---|---|---|---|
| cstar | uat |  basic | - | Kind: StorageV2, tier: Standard, min replication: ZRS, access tier: Hot, public: False, PiT restore: False, PiT Retention: 0, sftp: False |
| cstar | uat |  basic_public | - | Kind: StorageV2, tier: Standard, min replication: ZRS, access tier: Hot, public: True, PiT restore: False, PiT Retention: 0, sftp: False |
## dvopla
| Product  | Environment | Tier | Deprecated | Description |
|:-------------:|:----------------:|:---------:|:---------:|:----------------|
| dvopla | dev |  basic | - | Kind: StorageV2, tier: Standard, min replication: LRS, access tier: Hot, public: True, PiT restore: False, PiT Retention: 0, sftp: False |
| dvopla | dev |  sftp | - | Kind: StorageV2, tier: Standard, min replication: LRS, access tier: Hot, public: True, PiT restore: False, PiT Retention: 0, sftp: True |
## pagopa
| Product  | Environment | Tier | Deprecated | Description |
|:-------------:|:----------------:|:---------:|:---------:|:----------------|
| pagopa | dev |  basic | - | Kind: StorageV2, tier: Standard, min replication: LRS, access tier: Hot, public: False, PiT restore: False, PiT Retention: 0, sftp: False |
| pagopa | dev |  basic_public | **Deprecated** | Kind: StorageV2, tier: Standard, min replication: LRS, access tier: Hot, public: True, PiT restore: False, PiT Retention: 0, sftp: False |
| pagopa | dev |  sftp | - | Kind: StorageV2, tier: Standard, min replication: LRS, access tier: Hot, public: True, PiT restore: False, PiT Retention: 0, sftp: True |
|---|---|---|---|
| pagopa | prod |  backup30 | - | Kind: StorageV2, tier: Standard, min replication: ZRS, access tier: Hot, public: False, PiT restore: True, PiT Retention: 30, sftp: False |
| pagopa | prod |  backup7 | - | Kind: StorageV2, tier: Standard, min replication: ZRS, access tier: Hot, public: False, PiT restore: True, PiT Retention: 7, sftp: False |
| pagopa | prod |  basic | - | Kind: StorageV2, tier: Standard, min replication: ZRS, access tier: Hot, public: False, PiT restore: False, PiT Retention: 0, sftp: False |
| pagopa | prod |  sftp | - | Kind: StorageV2, tier: Standard, min replication: ZRS, access tier: Hot, public: True, PiT restore: False, PiT Retention: 0, sftp: True |
| pagopa | prod |  sftpBackup30 | - | Kind: StorageV2, tier: Standard, min replication: ZRS, access tier: Hot, public: True, PiT restore: True, PiT Retention: 30, sftp: True |
| pagopa | prod |  sftpBackup7 | - | Kind: StorageV2, tier: Standard, min replication: ZRS, access tier: Hot, public: True, PiT restore: True, PiT Retention: 7, sftp: True |
|---|---|---|---|
| pagopa | uat |  basic | - | Kind: StorageV2, tier: Standard, min replication: ZRS, access tier: Hot, public: True, PiT restore: False, PiT Retention: 0, sftp: False |
| pagopa | uat |  sftp | - | Kind: StorageV2, tier: Standard, min replication: ZRS, access tier: Hot, public: True, PiT restore: False, PiT Retention: 0, sftp: True |
