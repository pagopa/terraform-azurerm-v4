# ElasticSearch resources for monitoring an application

This module creates the elasticsearch resources required to monitor an application

## Configurations

## How to use it

This module provisions, for a single application monitored on Elasticsearch/Kibana, the full set of observability
resources needed to ingest, index, visualize and alert on its logs/APM data:

- Ingest pipelines (`elasticstack_elasticsearch_ingest_pipeline`), one per index defined in `configuration.indexTemplate`
- `@custom` and `@package` component templates and the related index templates
- Data streams (`configuration.dataStream`)
- Kibana data views: one "logs" data view (built from `configuration.dataView`) and one APM data view (built from
  `configuration.apmDataView`)
- Kibana saved objects imported from `.ndjson` files: dashboards (from `dashboard_folder`, plus the module's own
  built-in `logs-by-service` dashboard) and saved queries (from `query_folder`)
- Kibana alerting rules, built by merging:
  - application-specific alerts defined as `.yml` files in `alert_folder`
  - a built-in system alert (`overlog`, shipped with the module) that detects abnormal log volume increases

All resources are namespaced using `target_name`, `target_env` and `application_name`, so the same configuration can
be reused across environments/targets without name clashes.

### Required supporting files

Besides the `configuration` object, the module expects several folders/paths to already contain the supporting
artifacts referenced by the configuration:

| Variable | Expected content |
|----------|------------------|
| `library_index_custom_path` | `.json` files, one per `@custom` component template (referenced by `indexTemplate.*.customComponent`, or by `default_custom_component_name` when not set) |
| `library_index_package_path` | `.json` files, one per `@package` component template (referenced by `indexTemplate.*.packageComponent`, optional) |
| `library_ingest_pipeline_path` | `.json` files, one per ingest pipeline (referenced by `indexTemplate.*.ingestPipeline`) |
| `dashboard_folder` | `.ndjson` Kibana dashboard exports for this application |
| `query_folder` | `.ndjson` Kibana saved search/query exports for this application |
| `alert_folder` | `.yml` files, one per application-specific alert rule (see format below) |

### Basic example

```hcl
module "elastic_app_resources" {
  source = "./elastic_app_resources"

  target_name = "pagopa"
  target_env  = "prod"
  space_id    = "pagopa-prod"

  application_name = "my-service"

  library_index_custom_path    = "${path.module}/library/index/custom"
  library_index_package_path   = "${path.module}/library/index/package"
  library_ingest_pipeline_path = "${path.module}/library/ingest-pipeline"
  default_custom_component_name = "default"

  dashboard_folder = "${path.module}/applications/my-service/dashboards"
  query_folder     = "${path.module}/applications/my-service/queries"
  alert_folder     = "${path.module}/applications/my-service/alerts"

  ilm_name = "standard"

  configuration = {
    displayName = "My Service"

    indexTemplate = {
      logs = {
        indexPatterns  = ["logs"]
        ingestPipeline = "generic-logs"
        # uses default_custom_component_name because customComponent is not set
      }
    }

    dataStream = ["logs"]

    dataView = {
      indexIdentifiers = ["logs"]
    }

    apmDataView = {
      indexIdentifiers = ["my-service"]
    }
  }

  # at least one notification channel must be defined for the built-in system alert
  system_alert = {
    notification_channels = {
      email = {
        recipient_list_name = "platform-team"
      }
    }
  }
  

  system_alert_channels = {
    email = {
      enabled    = true
      recipients = { platform-team = ["team@example.com"] }
    }
  }
}
```

### Alert channels

`alert_channels` (for application alerts) and `system_alert_channels` (for the built-in `overlog` alert) share the
same shape and support four channel types: `email`, `slack`, `jsm` and `cloudo`. Each channel must be explicitly
`enabled` and have at least one recipient/connector defined:

```hcl
alert_channels = {
  email = {
    enabled    = true
    recipients = { platform-team = ["team@example.com", "oncall@example.com"] }
  }
  slack = {
    enabled    = true
    connectors = { platform-channel = "slack-connector-id" }
  }
  jsm = {
    enabled    = true
    connectors = { incidents = "jsm-connector-id" }
  }
  cloudo = {
    enabled    = true
    connectors = { aks-cluster = "cloudo-connector-id" }
  }
}
```

Each individual alert `.yml` file then references one of these recipients/connectors by name in its
`notification_channels` block (see below); the module validates at plan time that the referenced name exists and
that the corresponding channel is enabled.

### Alert configuration capabilities

#### Per-channel `notification_channels` fields

Each alert can notify any combination of the four channels at once (not just one); every enabled channel generates
its own Kibana action. The fields expected under `notification_channels` differ per channel:

| Channel | Required fields | Notes |
|---------|------------------|-------|
| `email` | `recipient_list_name` | Must be a key of `alert_channels.email.recipients` (or `system_alert_channels.email.recipients` for the system alert). Recipients list becomes the `to` field; `cc` is always empty. |
| `slack` | `connector_name` | Must be a key of `alert_channels.slack.connectors`. |
| `jsm` | `connector_name`, `priority` | `connector_name` must be a key of `alert_channels.jsm.connectors`; `priority` is forwarded as-is to the JSM `createAlert` action. |
| `cloudo` | `connector_name`, `rule`, `severity`, `type`, `attributes` | `connector_name` must be a key of `alert_channels.cloudo.connectors`; `type` must be one of `aks` (see `local.allowed_cloudo_types`); when `type = "aks"`, `attributes.namespace` is required. `rule`/`severity`/`attributes` are forwarded into the webhook body. |

```yaml
notification_channels:
  email:
    recipient_list_name: platform-team
  slack:
    connector_name: platform-channel
  jsm:
    connector_name: incidents
    priority: P2
  cloudo:
    connector_name: aks-cluster
    rule: high-error-rate
    severity: Sev2
    type: aks
    attributes:
      namespace: my-service-ns
```

All preconditions above are enforced at `terraform plan` time: an unknown recipient/connector name, a disabled
channel referenced by an alert, or missing `cloudo` fields will fail validation with a descriptive error that
includes the alert and application name.

#### Fired and recovered notifications

For every enabled channel the module creates two Kibana rule actions:
- a **fired** action (group `query matched` for `log_query`/`esql_query`/`apm_metric` alerts, or
  `custom_threshold.fired` for `custom_threshold` alerts), carrying a message template specific to the alert type
  (see `local.alert_messages`)
- a **recovered** action, sent when the rule condition clears, with a simple "Recovered - ..." message (for
  `jsm`/`cloudo` this maps to `closeAlert` / `monitorCondition: Resolved` instead of a new message)

Both actions use `notify_when = "onActionGroupChange"`, i.e. notifications are sent only when the alert status
changes (not on every schedule run).

#### Investigation guide and linked dashboards

An alert can optionally include an `investigation` block, surfaced in Kibana as the rule's investigation guide and
linked dashboards:

```yaml
investigation:
  message: |
    Runbook: check the linked dashboard for the affected service, then look up recent deployments.
  dashboards:
    - logs-by-service   # must match the filename (without .ndjson) of a dashboard in dashboard_folder,
                         # or the module's built-in "logs-by-service" dashboard
```

#### Rule enablement logic

An alert rule is actually enabled in Kibana only when **both** conditions hold:
- its own `enabled` field is `true` (default, if omitted)
- at least one of `alert_channels.email.enabled`, `alert_channels.jsm.enabled` or `alert_channels.slack.enabled` is
  `true` (note: `cloudo` alone does not count for this global switch)

This lets you keep alert definitions in place while temporarily disabling all notifications for an application (or
an environment) by toggling `alert_channels`, without deleting the `.yml` files.

#### Alert-type summary and mutual exclusivity

Exactly one of `log_query`, `custom_threshold`, `apm_metric` or `esql_query` must be set per alert; the module
rejects files that define more than one. Use:
- `log_query` for simple KQL threshold alerts on logs or APM data
- `custom_threshold` to combine multiple aggregations (e.g. an error ratio) with a custom `equation`, optionally
  grouped `group_by` a field (per-group alerting)
- `apm_metric` to reuse Kibana's built-in APM rule types (`latency`, `failed_transactions`, `error_count`,
  `anomaly`) without having to hand-write a query
- `esql_query` for arbitrary ES|QL-based alerting logic

### Application alert file format (`alert_folder`)

Every `.yml` file placed in `alert_folder` defines one Kibana alerting rule. Common fields:

```yaml
name: high-error-rate                 # required, used to build the rule display name
schedule: "5m"                        # required, Kibana cadence (e.g. "1m", "5m", "1h")
window:
  size: 5                             # required
  unit: m
trigger_after_consecutive_runs: 1      # optional, alert_delay
enabled: true                          # optional, defaults to true
notification_channels:
  email:
    recipient_list_name: platform-team # must match a key in alert_channels.email.recipients
  slack:
    connector_name: platform-channel   # must match a key in alert_channels.slack.connectors
```

Exactly one of the following alert-type blocks must then be added (they are mutually exclusive):

**`log_query`** – threshold alert over a KQL query on the "logs" or "apm" data view:
```yaml
log_query:
  data_view: logs                      # "logs" or "apm"
  query: "service.name: \"my-service\" and log.level: \"error\""
  aggregation:
    type: count                        # count | sum | avg | min | max
    # field: "my.numeric.field"        # required for sum/avg/min/max
  threshold:
    comparator: ">"                    # >, >=, <, <=, between, notBetween
    values: [50]                       # single value, or 2 values for between/notBetween
  exclude_hits_from_previous_run: false
```

**`custom_threshold`** – metric-based alert with one or more aggregations combined via an equation:
```yaml
custom_threshold:
  data_view: logs
  group_by: "service.name"
  aggregations:
    - name: errors
      aggregation: count
      filter: "log.level: \"error\""
    - name: total
      aggregation: count
  equation: "errors / total * 100"
  threshold:
    comparator: ">"
    values: [5]
  alert_on_no_data: false
```

**`apm_metric`** – built-in APM rule types (`latency`, `failed_transactions`, `error_count`, `anomaly`):
```yaml
apm_metric:
  metric: latency
  filter: "service.name: \"my-service\""
  threshold: [1000]
```
```yaml
apm_metric:
  metric: anomaly
  anomaly:
    service: my-service
    severity_type: critical            # critical | major | minor | warning
    detectors: [latency, failures]      # latency | throughput | failures
```

**`esql_query`** – ES|QL based alert:
```yaml
esql_query:
  query: "FROM logs-* | WHERE log.level == \"error\" | STATS count = COUNT(*)"
  group_by: all                        # all | row
  exclude_hits_from_previous_run: false
```

### Built-in system alert (`overlog`)

The module ships its own `overlog` alert (see `alert/platform_overlog_alert.yml`), which compares the log volume of
the last `window_size_hours` hours against the volume of a previous window shifted `lookback_comparison_hours` hours
back, and fires when the increase exceeds `threshold_percentage`:

If the previous window falls on a weekend day, the window is expanded to look in the first available working day before the weekend, so that weekend log volume drops do not trigger false positives.

```hcl
system_alert = {
  overlog = {
    window_size_hours         = 1
    lookback_comparison_hours = 24
    threshold_percentage      = 20
  }
  notification_channels = {
    slack = {
      connector_name = "platform-channel" # must match a key in system_alert_channels.slack.connectors
    }
  }
}
```

### Multiple index templates and data streams

`configuration.indexTemplate` is a map, so an application can define several index/pipeline combinations sharing the
same data view:

```hcl
configuration = {
  displayName = "My Service"

  indexTemplate = {
    logs = {
      indexPatterns    = ["logs"]
      ingestPipeline   = "generic-logs"
      customComponent  = "my-service-logs" # overrides default_custom_component_name
    }
    audit = {
      indexPatterns    = ["logs"]
      ingestPipeline   = "audit-logs"
      packageComponent = "audit-package"   # adds an extra @package component template
    }
  }

  dataStream = ["logs-my-service", "logs-audit"]

  dataView = {
    indexIdentifiers = ["logs"]
    runtimeFields = [
      {
        name = "is_error"
        runtimeField = {
          type = "boolean"
          script = {
            source = "emit(doc['log.level.keyword'].value == 'error')"
          }
        }
      }
    ]
  }
}
```

<!-- markdownlint-disable -->
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_elasticstack"></a> [elasticstack](#requirement\_elasticstack) | >= 0.16.5 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [elasticstack_elasticsearch_component_template.custom_index_component](https://registry.terraform.io/providers/elastic/elasticstack/latest/docs/resources/elasticsearch_component_template) | resource |
| [elasticstack_elasticsearch_component_template.package_index_component](https://registry.terraform.io/providers/elastic/elasticstack/latest/docs/resources/elasticsearch_component_template) | resource |
| [elasticstack_elasticsearch_data_stream.data_stream](https://registry.terraform.io/providers/elastic/elasticstack/latest/docs/resources/elasticsearch_data_stream) | resource |
| [elasticstack_elasticsearch_index_template.index_template](https://registry.terraform.io/providers/elastic/elasticstack/latest/docs/resources/elasticsearch_index_template) | resource |
| [elasticstack_elasticsearch_ingest_pipeline.ingest_pipeline](https://registry.terraform.io/providers/elastic/elasticstack/latest/docs/resources/elasticsearch_ingest_pipeline) | resource |
| [elasticstack_kibana_alerting_rule.alert](https://registry.terraform.io/providers/elastic/elasticstack/latest/docs/resources/kibana_alerting_rule) | resource |
| [elasticstack_kibana_data_view.kibana_apm_data_view](https://registry.terraform.io/providers/elastic/elasticstack/latest/docs/resources/kibana_data_view) | resource |
| [elasticstack_kibana_data_view.kibana_data_view](https://registry.terraform.io/providers/elastic/elasticstack/latest/docs/resources/kibana_data_view) | resource |
| [elasticstack_kibana_data_view.kibana_system_data_view](https://registry.terraform.io/providers/elastic/elasticstack/latest/docs/resources/kibana_data_view) | resource |
| [elasticstack_kibana_import_saved_objects.dashboard](https://registry.terraform.io/providers/elastic/elasticstack/latest/docs/resources/kibana_import_saved_objects) | resource |
| [elasticstack_kibana_import_saved_objects.query](https://registry.terraform.io/providers/elastic/elasticstack/latest/docs/resources/kibana_import_saved_objects) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_alert_channels"></a> [alert\_channels](#input\_alert\_channels) | Configuration for alert channels to be used in the application alerts. Each channel can be enabled or disabled, and if enabled, must have the necessary recipients or connectors defined. | <pre>object({<br/>    email = optional(object({<br/>      enabled    = bool<br/>      recipients = map(list(string))<br/>      }), {<br/>      enabled    = false<br/>      recipients = {}<br/>    })<br/>    slack = optional(object({<br/>      enabled    = bool<br/>      connectors = map(string)<br/>      }), {<br/>      enabled    = false<br/>      connectors = {}<br/>    })<br/>    jsm = optional(object({<br/>      enabled    = bool<br/>      connectors = map(string)<br/>      }), {<br/>      enabled    = false<br/>      connectors = {}<br/>    })<br/>    cloudo = optional(object({<br/>      enabled    = bool<br/>      connectors = map(string)<br/>      }), {<br/>      enabled    = false<br/>      connectors = {}<br/>    })<br/>  })</pre> | <pre>{<br/>  "cloudo": {<br/>    "connectors": {},<br/>    "enabled": false<br/>  },<br/>  "email": {<br/>    "enabled": false,<br/>    "recipients": {}<br/>  },<br/>  "jsm": {<br/>    "connectors": {},<br/>    "enabled": false<br/>  },<br/>  "slack": {<br/>    "connectors": {},<br/>    "enabled": false<br/>  }<br/>}</pre> | no |
| <a name="input_alert_folder"></a> [alert\_folder](#input\_alert\_folder) | Path to the alert containing folder for this application | `string` | n/a | yes |
| <a name="input_application_name"></a> [application\_name](#input\_application\_name) | Name of this application | `string` | n/a | yes |
| <a name="input_configuration"></a> [configuration](#input\_configuration) | Configuration for this application | <pre>object({<br/>    displayName = string<br/>    indexTemplate = map(object({<br/>      indexPatterns    = list(string)<br/>      customComponent  = optional(string, null)<br/>      packageComponent = optional(string, null)<br/>      ingestPipeline   = string<br/>    }))<br/>    dataStream = list(string)<br/>    dataView = object({<br/>      indexIdentifiers = list(string)<br/>      runtimeFields    = optional(list(any), [])<br/>    })<br/>    apmDataView = optional(object({<br/>      indexIdentifiers = list(string)<br/>      }), {<br/>      indexIdentifiers = []<br/>    })<br/><br/>  })</pre> | n/a | yes |
| <a name="input_custom_index_component_parameters"></a> [custom\_index\_component\_parameters](#input\_custom\_index\_component\_parameters) | Additional parameters to be used in the index component templates. The key is the parameter name, the value is the parameter value | `map(string)` | `{}` | no |
| <a name="input_dashboard_folder"></a> [dashboard\_folder](#input\_dashboard\_folder) | Path to the dashboard containing folder for this application | `string` | n/a | yes |
| <a name="input_default_custom_component_name"></a> [default\_custom\_component\_name](#input\_default\_custom\_component\_name) | Name of the default @custom index component to be used if none is defined in this app configuration | `string` | n/a | yes |
| <a name="input_ilm_name"></a> [ilm\_name](#input\_ilm\_name) | Name of the ilm to be used for this application indexes (must already exist) | `string` | n/a | yes |
| <a name="input_library_index_custom_path"></a> [library\_index\_custom\_path](#input\_library\_index\_custom\_path) | Path to the library folder of @custom index components | `string` | n/a | yes |
| <a name="input_library_index_package_path"></a> [library\_index\_package\_path](#input\_library\_index\_package\_path) | Path to the library folder of @package index components | `string` | n/a | yes |
| <a name="input_library_ingest_pipeline_path"></a> [library\_ingest\_pipeline\_path](#input\_library\_ingest\_pipeline\_path) | Path to the library folder of ingestion pipelines | `string` | n/a | yes |
| <a name="input_query_folder"></a> [query\_folder](#input\_query\_folder) | Path to the query containing folder for this application | `string` | n/a | yes |
| <a name="input_space_id"></a> [space\_id](#input\_space\_id) | Kibana space identifier where to create the data views and dashboards for this application | `string` | n/a | yes |
| <a name="input_space_name"></a> [space\_name](#input\_space\_name) | Kibana space name where to create the data views and dashboards for this application. Used in resources display name | `string` | n/a | yes |
| <a name="input_system_alert"></a> [system\_alert](#input\_system\_alert) | Configuration for embedded system alerts. | <pre>object({<br/>    overlog = optional(object({<br/>      window_size_hours         = optional(number, 1)    # time window to evaluate the overlog alert on<br/>      lookback_comparison_hours = optional(number, 24)   # compoare the current time window to the previous time window shifted this many hours back in time<br/>      threshold_percentage      = optional(number, 20)   # max allowed increase in log volume between the current time window and the previous time window<br/>      min_count_threshold       = optional(number, 5000) # min number of recors to be found in the current time window to trigger the alert. This is to avoid triggering the alert on low volume logs that may have a high percentage increase but are not significant.<br/>      }), {<br/>      window_size_hours         = 1<br/>      lookback_comparison_hours = 24<br/>      threshold_percentage      = 20<br/>      min_count_threshold       = 5000<br/>    })<br/>    notification_channels = object({ # defines the notification channels to be used for embedded system alerts. At least one channel must be defined.<br/>      email = optional(object({<br/>        recipient_list_name = string<br/>      }), null)<br/>      slack = optional(object({<br/>        connector_name = string<br/>      }), null)<br/>      jsm = optional(object({<br/>        connector_name = string<br/>        priority       = string<br/>      }), null)<br/>    })<br/>  })</pre> | n/a | yes |
| <a name="input_system_alert_channels"></a> [system\_alert\_channels](#input\_system\_alert\_channels) | Configuration for alert channels to be used in the embedded system alerts. Each channel can be enabled or disabled, and if enabled, must have the necessary recipients or connectors defined. | <pre>object({<br/>    email = optional(object({<br/>      enabled    = bool<br/>      recipients = map(list(string))<br/>      }), {<br/>      enabled    = false<br/>      recipients = {}<br/>    })<br/>    slack = optional(object({<br/>      enabled    = bool<br/>      connectors = map(string)<br/>      }), {<br/>      enabled    = false<br/>      connectors = {}<br/>    })<br/>    jsm = optional(object({<br/>      enabled    = bool<br/>      connectors = map(string)<br/>      }), {<br/>      enabled    = false<br/>      connectors = {}<br/>    })<br/>    cloudo = optional(object({<br/>      enabled    = bool<br/>      connectors = map(string)<br/>      }), {<br/>      enabled    = false<br/>      connectors = {}<br/>    })<br/>  })</pre> | <pre>{<br/>  "cloudo": {<br/>    "connectors": {},<br/>    "enabled": false<br/>  },<br/>  "email": {<br/>    "enabled": false,<br/>    "recipients": {}<br/>  },<br/>  "jsm": {<br/>    "connectors": {},<br/>    "enabled": false<br/>  },<br/>  "slack": {<br/>    "connectors": {},<br/>    "enabled": false<br/>  }<br/>}</pre> | no |
| <a name="input_system_space_id"></a> [system\_space\_id](#input\_system\_space\_id) | Kibana space identifier where to create the system resources related to this application | `string` | n/a | yes |
| <a name="input_target_env"></a> [target\_env](#input\_target\_env) | Name of the monitored target environment containing this application | `string` | n/a | yes |
| <a name="input_target_name"></a> [target\_name](#input\_target\_name) | Name of the monitored target containing this application. eg: pagopa, cstar, p4pa | `string` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
