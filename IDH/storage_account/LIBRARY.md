# IDH storage_account Resources

## cstar
| Product  | Environment | Tier | Deprecated | Description |
|:-------------:|:----------------:|:---------:|:---------:|:----------------|
| cstar | dev |  basic | No | Kind: StorageV2, tier: Standard, min replication: LRS, access tier: Hot, public: False, PiT restore: False, PiT Retention: 0, sftp: False |
| cstar | dev |  basic_audit_cool | No | Kind: StorageV2, tier: Standard, min replication: LRS, access tier: Cool, public: False, PiT restore: False, PiT Retention: 0, sftp: False |
| cstar | dev |  basic_public | No | Kind: StorageV2, tier: Standard, min replication: LRS, access tier: Hot, public: True, PiT restore: False, PiT Retention: 0, sftp: False |
|---|---|---|---|
| cstar | prod |  backup30 | No | Kind: StorageV2, tier: Standard, min replication: ZRS, access tier: Hot, public: False, PiT restore: True, PiT Retention: 30, sftp: False |
| cstar | prod |  backup7 | No | Kind: StorageV2, tier: Standard, min replication: ZRS, access tier: Hot, public: False, PiT restore: True, PiT Retention: 7, sftp: False |
| cstar | prod |  backup7_public | No | Kind: StorageV2, tier: Standard, min replication: ZRS, access tier: Hot, public: True, PiT restore: True, PiT Retention: 7, sftp: False |
| cstar | prod |  basic | No | Kind: StorageV2, tier: Standard, min replication: ZRS, access tier: Hot, public: False, PiT restore: True, PiT Retention: 7, sftp: False |
| cstar | prod |  basic_audit | No | Kind: StorageV2, tier: Standard, min replication: ZRS, access tier: Hot, public: False, PiT restore: False, PiT Retention: 0, sftp: False |
| cstar | prod |  basic_audit_cool | No | Kind: StorageV2, tier: Standard, min replication: ZRS, access tier: Cool, public: False, PiT restore: False, PiT Retention: 0, sftp: False |
| cstar | prod |  basic_public | No | Kind: StorageV2, tier: Standard, min replication: ZRS, access tier: Hot, public: True, PiT restore: True, PiT Retention: 7, sftp: False |
| cstar | prod |  basic_public_no_softdel | No | Kind: StorageV2, tier: Standard, min replication: ZRS, access tier: Hot, public: True, PiT restore: False, PiT Retention: 0, sftp: False |
|---|---|---|---|
| cstar | uat |  basic | No | Kind: StorageV2, tier: Standard, min replication: ZRS, access tier: Hot, public: False, PiT restore: False, PiT Retention: 0, sftp: False |
| cstar | uat |  basic_audit_cool | No | Kind: StorageV2, tier: Standard, min replication: ZRS, access tier: Cool, public: False, PiT restore: False, PiT Retention: 0, sftp: False |
| cstar | uat |  basic_public | No | Kind: StorageV2, tier: Standard, min replication: ZRS, access tier: Hot, public: True, PiT restore: False, PiT Retention: 0, sftp: False |
## dvopla
| Product  | Environment | Tier | Deprecated | Description |
|:-------------:|:----------------:|:---------:|:---------:|:----------------|
| dvopla | dev |  basic | No | Kind: StorageV2, tier: Standard, min replication: LRS, access tier: Hot, public: True, PiT restore: False, PiT Retention: 0, sftp: False |
| dvopla | dev |  sftp | No | Kind: StorageV2, tier: Standard, min replication: LRS, access tier: Hot, public: True, PiT restore: False, PiT Retention: 0, sftp: True |
## pagopa
| Product  | Environment | Tier | Deprecated | Description |
|:-------------:|:----------------:|:---------:|:---------:|:----------------|
| pagopa | dev |  basic | No | Kind: StorageV2, tier: Standard, min replication: LRS, access tier: Hot, public: False, PiT restore: False, PiT Retention: 0, sftp: False |
| pagopa | dev |  ~~basic_public~~ | **Yes** | Kind: StorageV2, tier: Standard, min replication: LRS, access tier: Hot, public: True, PiT restore: False, PiT Retention: 0, sftp: False |
| pagopa | dev |  sftp | No | Kind: StorageV2, tier: Standard, min replication: LRS, access tier: Hot, public: True, PiT restore: False, PiT Retention: 0, sftp: True |
|---|---|---|---|
| pagopa | prod |  backup30 | No | Kind: StorageV2, tier: Standard, min replication: ZRS, access tier: Hot, public: False, PiT restore: True, PiT Retention: 30, sftp: False |
| pagopa | prod |  backup7 | No | Kind: StorageV2, tier: Standard, min replication: ZRS, access tier: Hot, public: False, PiT restore: True, PiT Retention: 7, sftp: False |
| pagopa | prod |  basic | No | Kind: StorageV2, tier: Standard, min replication: ZRS, access tier: Hot, public: False, PiT restore: False, PiT Retention: 0, sftp: False |
| pagopa | prod |  sftp | No | Kind: StorageV2, tier: Standard, min replication: ZRS, access tier: Hot, public: True, PiT restore: False, PiT Retention: 0, sftp: True |
| pagopa | prod |  sftpBackup30 | No | Kind: StorageV2, tier: Standard, min replication: ZRS, access tier: Hot, public: True, PiT restore: True, PiT Retention: 30, sftp: True |
| pagopa | prod |  sftpBackup7 | No | Kind: StorageV2, tier: Standard, min replication: ZRS, access tier: Hot, public: True, PiT restore: True, PiT Retention: 7, sftp: True |
|---|---|---|---|
| pagopa | uat |  basic | No | Kind: StorageV2, tier: Standard, min replication: ZRS, access tier: Hot, public: False, PiT restore: False, PiT Retention: 0, sftp: False |
| pagopa | uat |  sftp | No | Kind: StorageV2, tier: Standard, min replication: ZRS, access tier: Hot, public: True, PiT restore: False, PiT Retention: 0, sftp: True |
