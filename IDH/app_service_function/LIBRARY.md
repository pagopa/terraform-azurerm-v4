# IDH app_service_function Resources

## pagopa
| Product  | Environment | Tier | Deprecated | Description |
|:-------------:|:----------------:|:---------:|:---------:|:----------------|
| pagopa | dev |  basic | No | SKU: Basic B1, zone balancing: False, public network access: True, private endpoint enabled: False, ip restriction default action: Deny, staging slot: False, autoscale enabled: False, plan type: external |
| pagopa | dev |  basic_private | No | SKU: Basic B1, zone balancing: False, public network access: True, private endpoint enabled: True, ip restriction default action: Deny, staging slot: False, autoscale enabled: False, plan type: external |
|---|---|---|---|
| pagopa | prod |  basic | No | SKU: Basic B1, zone balancing: False, public network access: True, private endpoint enabled: True, ip restriction default action: Deny, staging slot: False, autoscale enabled: False, plan type: external |
| pagopa | prod |  premium | No | SKU: Premium P1v3, zone balancing: True, public network access: True, private endpoint enabled: True, ip restriction default action: Deny, staging slot: True, autoscale enabled: True, plan type: external |
| pagopa | prod |  premium_high_load | No | SKU: Premium P3v3, zone balancing: True, public network access: True, private endpoint enabled: True, ip restriction default action: Deny, staging slot: True, autoscale enabled: True, plan type: external |
|---|---|---|---|
| pagopa | uat |  basic | No | SKU: Basic B1, zone balancing: False, public network access: True, private endpoint enabled: True, ip restriction default action: Deny, staging slot: False, autoscale enabled: False, plan type: external |
| pagopa | uat |  premium | No | SKU: Premium P1v3, zone balancing: False, public network access: True, private endpoint enabled: True, ip restriction default action: Deny, staging slot: False, autoscale enabled: False, plan type: external |
