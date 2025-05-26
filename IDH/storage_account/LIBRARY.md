# IDH storage_account resources
|Platform| Environment| Name | Description | 
|------|---------|----|---|
|pagopa|dev|basic| Kind: StorageV2, tier: Standard, min replication: LRS, access tier: Hot, public: True, PiT restore: False, PiT Retention: 0 |
|pagopa|prod|backup30| Kind: StorageV2, tier: Standard, min replication: ZRS, access tier: Hot, public: False, PiT restore: True, PiT Retention: 30 |
|pagopa|prod|backup7| Kind: StorageV2, tier: Standard, min replication: ZRS, access tier: Hot, public: False, PiT restore: True, PiT Retention: 7 |
|pagopa|prod|basic| Kind: StorageV2, tier: Standard, min replication: ZRS, access tier: Hot, public: False, PiT restore: False, PiT Retention: 7 |
|pagopa|uat|basic| Kind: StorageV2, tier: Standard, min replication: ZRS, access tier: Hot, public: False, PiT restore: False, PiT Retention: 0 |
