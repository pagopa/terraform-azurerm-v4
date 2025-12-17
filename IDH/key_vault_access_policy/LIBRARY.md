# 📚 IDH key_vault_access_policy Resources

## cstar
| 🖥️ Product  | 🌍 Environment | 🔤 Tier | 📝 Description |
|:-------------:|:----------------:|:---------:|:----------------|
| cstar | dev |  admin | key: ['Get', 'List', 'Update', 'Create', 'Import', 'Delete', 'Encrypt', 'Decrypt', 'Backup', 'Purge', 'Recover', 'Restore', 'Sign', 'UnwrapKey', 'Update', 'Verify', 'WrapKey', 'Release', 'Rotate', 'GetRotationPolicy', 'SetRotationPolicy'], secret: ['Get', 'List', 'Set', 'Delete', 'Backup', 'Purge', 'Recover', 'Restore'], storage: [], certificate: ['Get', 'List', 'Update', 'Create', 'Import', 'Delete', 'Restore', 'Purge', 'Recover', 'Backup', 'ManageContacts', 'ManageIssuers', 'GetIssuers', 'ListIssuers', 'SetIssuers', 'DeleteIssuers'] |
| cstar | dev |  developer | key: ['Get', 'List', 'Update', 'Create', 'Import', 'Delete', 'Encrypt', 'Decrypt', 'Rotate', 'GetRotationPolicy'], secret: ['Get', 'List', 'Set', 'Delete', 'Backup', 'Purge', 'Recover', 'Restore'], storage: [], certificate: ['Get', 'List', 'Update', 'Create', 'Import', 'Delete', 'Restore', 'Purge', 'Recover'] |
| cstar | dev |  external | key: ['Get', 'List', 'Update', 'Create', 'Import', 'Delete', 'Encrypt', 'Decrypt', 'Rotate', 'GetRotationPolicy'], secret: ['Get', 'List', 'Set', 'Delete', 'Backup', 'Purge', 'Recover', 'Restore'], storage: [], certificate: ['Get', 'List', 'Update', 'Create', 'Import', 'Delete', 'Restore', 'Purge', 'Recover'] |
| cstar | dev |  reader | key: ['Get', 'List'], secret: ['Get', 'List'], storage: [], certificate: ['Get', 'List'] |
|---|---|---|---|
| cstar | prod |  admin | key: ['Get', 'List', 'Update', 'Create', 'Import', 'Delete', 'Encrypt', 'Decrypt', 'Backup', 'Purge', 'Recover', 'Restore', 'Sign', 'UnwrapKey', 'Update', 'Verify', 'WrapKey', 'Release', 'Rotate', 'GetRotationPolicy', 'SetRotationPolicy'], secret: ['Get', 'List', 'Set', 'Delete', 'Backup', 'Purge', 'Recover', 'Restore'], storage: [], certificate: ['Get', 'List', 'Update', 'Create', 'Import', 'Delete', 'Restore', 'Purge', 'Recover', 'Backup', 'ManageContacts', 'ManageIssuers', 'GetIssuers', 'ListIssuers', 'SetIssuers', 'DeleteIssuers'] |
| cstar | prod |  developer | key: ['Get', 'List', 'Encrypt', 'Decrypt'], secret: ['Get', 'List'], storage: [], certificate: ['Get', 'List'] |
| cstar | prod |  oncall | key: ['Get', 'List', 'Encrypt', 'Decrypt'], secret: ['Get', 'List'], storage: [], certificate: ['Get', 'List'] |
| cstar | prod |  reader | key: ['Get', 'List'], secret: ['Get', 'List'], storage: [], certificate: ['Get', 'List'] |
|---|---|---|---|
| cstar | uat |  admin | key: ['Get', 'List', 'Update', 'Create', 'Import', 'Delete', 'Encrypt', 'Decrypt', 'Backup', 'Purge', 'Recover', 'Restore', 'Sign', 'UnwrapKey', 'Update', 'Verify', 'WrapKey', 'Release', 'Rotate', 'GetRotationPolicy', 'SetRotationPolicy'], secret: ['Get', 'List', 'Set', 'Delete', 'Backup', 'Purge', 'Recover', 'Restore'], storage: [], certificate: ['Get', 'List', 'Update', 'Create', 'Import', 'Delete', 'Restore', 'Purge', 'Recover', 'Backup', 'ManageContacts', 'ManageIssuers', 'GetIssuers', 'ListIssuers', 'SetIssuers', 'DeleteIssuers'] |
| cstar | uat |  developer | key: ['Get', 'List', 'Update', 'Create', 'Import', 'Delete', 'Encrypt', 'Decrypt', 'Rotate', 'GetRotationPolicy'], secret: ['Get', 'List', 'Set', 'Delete', 'Backup', 'Purge', 'Recover', 'Restore'], storage: [], certificate: ['Get', 'List', 'Update', 'Create', 'Import', 'Delete', 'Restore', 'Purge', 'Recover'] |
| cstar | uat |  external | key: ['Get', 'List', 'Encrypt', 'Decrypt'], secret: ['Get', 'List'], storage: [], certificate: ['Get', 'List'] |
| cstar | uat |  reader | key: ['Get', 'List'], secret: ['Get', 'List'], storage: [], certificate: ['Get', 'List'] |
