locals {
  data_streams   = { for d in var.configuration.dataStream : d => d }
  application_id = "${var.application_name}-${var.target_env}"
  dashboards     = { for df in fileset("${var.dashboard_folder}", "/*.ndjson") : trimsuffix(basename(df), ".ndjson") => "${var.dashboard_folder}/${df}" }
  queries        = { for qf in fileset("${var.query_folder}", "/*.ndjson") : trimsuffix(basename(qf), ".ndjson") => "${var.query_folder}/${qf}" }
  alerts         = { for af in fileset("${var.alert_folder}", "/*.yml") : trimsuffix(basename(af), ".yml") => yamldecode(file("${var.alert_folder}/${af}")) }

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

  alert_message = "Elasticsearch query rule {{rule.name}} is active: \n - Value: {{context.value}} \n - Conditions Met: {{context.conditions}} over {{rule.params.timeWindowSize}}'{{rule.params.timeWindowUnit}}\n- Timestamp: {{context.date}}\n- Link: {{context.link}}"

  rule_type_id_map = {
    "latency" = "apm.transaction_duration"
    "failed_transactions" = "apm.transaction_error_rate"
    "anomaly" = "apm.anomaly"
    "error_count" = "apm.error_rate"
  }

  anomaly_detector_map = {
    latency = "txLatency",
    throughput = "txThroughput",
    failures = "txFailureRate"
  }
}
