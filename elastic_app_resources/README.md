# ElasticSearch resources for monitoring an application

This module creates the elasticsearch resources required to monitor an application

## Configurations

## How to use it

TODO

<!-- markdownlint-disable -->
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_elasticstack"></a> [elasticstack](#requirement\_elasticstack) | ~> 0.11 |

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
| [elasticstack_kibana_import_saved_objects.dashboard](https://registry.terraform.io/providers/elastic/elasticstack/latest/docs/resources/kibana_import_saved_objects) | resource |
| [elasticstack_kibana_import_saved_objects.query](https://registry.terraform.io/providers/elastic/elasticstack/latest/docs/resources/kibana_import_saved_objects) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_alert_channels"></a> [alert\_channels](#input\_alert\_channels) | Configuration for alert channels to be used in the application alerts. Each channel can be enabled or disabled, and if enabled, must have the necessary recipients or connectors defined. | <pre>object({<br/>    email = optional(object({<br/>      enabled    = bool<br/>      recipients = map(list(string))<br/>      }), {<br/>      enabled    = false<br/>      recipients = {}<br/>    })<br/>    slack = optional(object({<br/>      enabled    = bool<br/>      connectors = map(string)<br/>      }), {<br/>      enabled    = false<br/>      connectors = {}<br/>    })<br/>    opsgenie = optional(object({<br/>      enabled    = bool<br/>      connectors = map(string)<br/>      }), {<br/>      enabled    = false<br/>      connectors = {}<br/>    })<br/>    cloudo = optional(object({<br/>      enabled    = bool<br/>      connectors = map(string)<br/>      }), {<br/>      enabled    = false<br/>      connectors = {}<br/>    })<br/>  })</pre> | <pre>{<br/>  "cloudo": {<br/>    "connectors": {},<br/>    "enabled": false<br/>  },<br/>  "email": {<br/>    "enabled": false,<br/>    "recipients": {}<br/>  },<br/>  "opsgenie": {<br/>    "connectors": {},<br/>    "enabled": false<br/>  },<br/>  "slack": {<br/>    "connectors": {},<br/>    "enabled": false<br/>  }<br/>}</pre> | no |
| <a name="input_alert_folder"></a> [alert\_folder](#input\_alert\_folder) | Path to the alert containing folder for this application | `string` | n/a | yes |
| <a name="input_application_name"></a> [application\_name](#input\_application\_name) | Name of this application | `string` | n/a | yes |
| <a name="input_configuration"></a> [configuration](#input\_configuration) | Configuration for this application | <pre>object({<br/>    displayName = string<br/>    indexTemplate = map(object({<br/>      indexPatterns    = list(string)<br/>      customComponent  = optional(string, null)<br/>      packageComponent = optional(string, null)<br/>      ingestPipeline   = string<br/>    }))<br/>    dataStream = list(string)<br/>    dataView = object({<br/>      indexIdentifiers = list(string)<br/>      runtimeFields    = optional(list(any), [])<br/>    })<br/>    apmDataView = optional(object({<br/>      indexIdentifiers = list(string)<br/>      }), {<br/>      indexIdentifiers = []<br/>    })<br/><br/>  })</pre> | n/a | yes |
| <a name="input_custom_index_component_parameters"></a> [custom\_index\_component\_parameters](#input\_custom\_index\_component\_parameters) | Additional parameters to be used in the index component templates. The key is the parameter name, the value is the parameter value | `map(string)` | `{}` | no |
| <a name="input_dashboard_folder"></a> [dashboard\_folder](#input\_dashboard\_folder) | Path to the dashboard containing folder for this application | `string` | n/a | yes |
| <a name="input_default_custom_component_name"></a> [default\_custom\_component\_name](#input\_default\_custom\_component\_name) | Name of the default @custom index component to be used if none is defined in this app configuration | `string` | n/a | yes |
| <a name="input_email_recipients"></a> [email\_recipients](#input\_email\_recipients) | (Optional) Map of email recipients for alert notifications. The key is the name of the recipient group, and the value is a list of email addresses. | `map(list(string))` | `{}` | no |
| <a name="input_ilm_name"></a> [ilm\_name](#input\_ilm\_name) | Name of the ilm to be used for this application indexes (must already exist) | `string` | n/a | yes |
| <a name="input_library_index_custom_path"></a> [library\_index\_custom\_path](#input\_library\_index\_custom\_path) | Path to the library folder of @custom index components | `string` | n/a | yes |
| <a name="input_library_index_package_path"></a> [library\_index\_package\_path](#input\_library\_index\_package\_path) | Path to the library folder of @package index components | `string` | n/a | yes |
| <a name="input_library_ingest_pipeline_path"></a> [library\_ingest\_pipeline\_path](#input\_library\_ingest\_pipeline\_path) | Path to the library folder of ingestion pipelines | `string` | n/a | yes |
| <a name="input_query_folder"></a> [query\_folder](#input\_query\_folder) | Path to the query containing folder for this application | `string` | n/a | yes |
| <a name="input_space_id"></a> [space\_id](#input\_space\_id) | Kibana space identifier where to create the data views and dashboards for this application | `string` | n/a | yes |
| <a name="input_target_env"></a> [target\_env](#input\_target\_env) | Name of the monitored target environment containing this application | `string` | n/a | yes |
| <a name="input_target_name"></a> [target\_name](#input\_target\_name) | Name of the monitored target containing this application. eg: pagopa, cstar, p4pa | `string` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
