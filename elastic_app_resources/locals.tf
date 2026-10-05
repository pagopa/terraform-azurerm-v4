locals {
  data_streams      = { for d in var.configuration.dataStream : d => d }
  application_id    = "${var.application_name}-${var.target_env}"
  dashboards        = { for df in fileset("${var.dashboard_folder}", "/*.ndjson") : trimsuffix(basename(df), ".ndjson") => "${var.dashboard_folder}/${df}" }
  system_dashboards = { for df in fileset("${path.module}/dashboard", "/*.ndjson") : trimsuffix(basename(df), ".ndjson") => "${path.module}/dashboard/${df}" }
  queries           = { for qf in fileset("${var.query_folder}", "/*.ndjson") : trimsuffix(basename(qf), ".ndjson") => "${var.query_folder}/${qf}" }
  system_alerts     = { for a in fileset("${path.module}/alert", "/*.yml") : trimsuffix(basename(a), ".yml") => merge(yamldecode(templatefile("${path.module}/alert/${a}", merge(local.system_alert_variables, local.alert_variables))), { alert_channels : var.system_alert_channels }) }
  alerts            = { for af in fileset("${var.alert_folder}", "/*.yml") : trimsuffix(basename(af), ".yml") => merge(yamldecode(templatefile("${var.alert_folder}/${af}", local.alert_variables)), { alert_channels : var.alert_channels }) }

  elastic_namespace = "${var.target_name}.${var.target_env}"

  index_custom_component = { for k, v in var.configuration.indexTemplate : k => jsondecode(templatefile("${var.library_index_custom_path}/${lookup(v, "customComponent", var.default_custom_component_name)}.json", merge({
    name      = "${k}-${local.application_id}"
    pipeline  = elasticstack_elasticsearch_ingest_pipeline.ingest_pipeline[k].name
    lifecycle = "${var.target_name}-${var.target_env}-${var.ilm_name}-ilm"
  }, var.custom_index_component_parameters))) }

  index_package_component = { for k, v in var.configuration.indexTemplate : k => jsondecode(templatefile("${var.library_index_package_path}/${v.packageComponent}.json", {
    name = "${k}-${local.application_id}"
    })) if lookup(v, "packageComponent", null) != null
  }

  runtime_fields = { for field in lookup(var.configuration.dataView, "runtimeFields", {}) : field.name => {
    type          = field.runtimeField.type
    script_source = field.runtimeField.script.source
    }
  }

  ingest_pipeline = { for k, v in var.configuration.indexTemplate : k => jsondecode(file("${var.library_ingest_pipeline_path}/${v.ingestPipeline}.json")) }


  alert_messages = {
    log_query        = "Elasticsearch query rule {{rule.name}} is active: \n - Value: {{context.value}} \n - Conditions Met: {{context.conditions}} over {{rule.params.timeWindowSize}}'{{rule.params.timeWindowUnit}}\n- Timestamp: {{context.date}}\n- Link: {{context.link}} \n Check the alert details if there is any investigation manual or dashboard defined"
    custom_threshold = "Elasticsearch custom threshold alert {{rule.name}} is active. \n {{context.reason}}  \n [View alert details]({{context.alertDetailsUrl}}) \n Check the alert details if there is any investigation manual or dashboard defined"
    apm_anomaly      = "{{context.reason}} \n{{rule.name}} is active with the following conditions: \n - Service name: {{context.serviceName}} \n - Transaction type: {{context.transactionType}} \n - Environment: {{context.environment}} \n - Severity: {{context.triggerValue}} \n - Threshold: {{context.threshold}} \n - Timestamp: {{context.date}} \n - Link: {{context.link}} \n [View alert details]({{context.alertDetailsUrl}})\n Check the alert details if there is any investigation manual or dashboard defined"
    esql_query       = "ES|QL query rule {{rule.name}} is active: \n - Value: {{context.value}} \n - Conditions Met: {{context.conditions}} over {{rule.params.timeWindowSize}}'{{rule.params.timeWindowUnit}}\n- Timestamp: {{context.date}}\n- Link: {{context.link}}\n Check the alert details if there is any investigation manual or dashboard defined"
  }

  rule_type_id_map = {
    "latency"             = "apm.transaction_duration"
    "failed_transactions" = "apm.transaction_error_rate"
    "anomaly"             = "apm.anomaly"
    "error_count"         = "apm.error_rate"
  }

  allowed_data_views    = ["logs", "apm"]
  allowed_esql_group_by = ["all", "row"]
  allowed_aggregations  = ["count", "avg", "sum", "min", "max", "cardinality", "rate", "p95", "p99", "last_value"]
  allowed_cloudo_types  = ["aks"]

  anomaly_detector_map = {
    latency    = "txLatency",
    throughput = "txThroughput",
    failures   = "txFailureRate"
  }

  alert_variables = {
    env       = var.target_env
    env_short = substr(var.target_env, 0, 1)
    namespace = local.elastic_namespace
  }

  system_alert_variables = {
    space_id = var.space_id
    overlog = {
      window_size_hours                   = var.system_alert.overlog.window_size_hours
      threshold_percentage                = var.system_alert.overlog.threshold_percentage
      max_lookback_hours                  = var.system_alert.overlog.lookback_comparison_hours + var.system_alert.overlog.window_size_hours
      min_lookback_hours                  = var.system_alert.overlog.lookback_comparison_hours
      frequency_hours                     = var.system_alert.overlog.window_size_hours
      max_lookback_hours_skip_on_saturday = var.system_alert.overlog.lookback_comparison_hours + var.system_alert.overlog.window_size_hours + 24
      max_lookback_hours_skip_on_sunday   = var.system_alert.overlog.lookback_comparison_hours + var.system_alert.overlog.window_size_hours + 48
      min_lookback_hours_skip_on_saturday = var.system_alert.overlog.lookback_comparison_hours + 24
      min_lookback_hours_skip_on_sunday   = var.system_alert.overlog.lookback_comparison_hours + 48
    }
    data_view             = elasticstack_kibana_data_view.kibana_data_view.data_view.title
    notification_channels = var.system_alert.notification_channels
  }
}
