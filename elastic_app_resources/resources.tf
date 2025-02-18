locals {
  data_streams   = { for d in var.configuration.dataStream : d => d }
  application_id = "${var.application_name}-${var.target_env}"
  dashboards     = { for df in fileset("${var.dashboard_folder}", "/*.ndjson") : trimsuffix(basename(df), ".ndjson") => "${var.dashboard_folder}/${df}" }
  queries        = { for df in fileset("${var.query_folder}", "/*.ndjson") : trimsuffix(basename(df), ".ndjson") => "${var.query_folder}/${df}" }

  index_custom_component = { for k, v in var.configuration.indexTemplate : k => jsondecode(templatefile("${var.library_index_custom_path}/${lookup(v, "customComponent", var.default_custom_component_name)}.json", {
    name      = "${k}-${local.application_id}"
    pipeline  = elasticstack_elasticsearch_ingest_pipeline.ingest_pipeline[k].name
    lifecycle = "${var.target_name}-${var.target_env}-${var.ilm_name}-ilm"
  })) }

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

}

output "test" {
  value = local.index_custom_component
}

resource "elasticstack_elasticsearch_ingest_pipeline" "ingest_pipeline" {
  for_each    = local.ingest_pipeline
  name        = "${local.application_id}-${each.key}-pipeline"
  description = "Ingest pipeline for ${var.configuration.displayName} ${each.key} ${var.target_name} ${var.target_env}"

  processors = [for p in local.ingest_pipeline[each.key].processors : jsonencode(p)]
  on_failure = length(lookup(local.ingest_pipeline[each.key], "onFailure", [])) > 0 ? [for p in lookup(local.ingest_pipeline[each.key], "onFailure", []) : jsonencode(p)] : null
}

resource "elasticstack_elasticsearch_component_template" "custom_index_component" {
  for_each = local.index_custom_component
  name     = "${local.application_id}-${each.key}@custom"
  template {

    settings = lookup(each.value.template, "settings", null) != null ? jsonencode(lookup(each.value.template, "settings", null)) : "${jsonencode(each.value.template)}"
    mappings = lookup(each.value.template, "mappings", null) != null ? jsonencode(lookup(each.value.template, "mappings", null)) : "{}"
  }

  metadata = jsonencode(lookup(each.value, "_meta", null))
}

resource "elasticstack_elasticsearch_component_template" "package_index_component" {
  for_each = local.index_package_component

  name = "${local.application_id}-${each.key}@package"

  template {

    settings = jsonencode(lookup(each.value, "settings", null))
    mappings = jsonencode(lookup(each.value, "mappings", null))
  }

  metadata = jsonencode(lookup(each.value, "_meta", null))
}

resource "elasticstack_elasticsearch_index_template" "index_template" {
  for_each = var.configuration.indexTemplate
  name     = "${local.application_id}-${each.key}-idxtpl"

  priority       = 500
  index_patterns = [for p in each.value.indexPatterns : "${p}-${var.target_name}.${var.target_env}"]
  composed_of = concat(
    (lookup(each.value, "packageComponent", null) != null ? [elasticstack_elasticsearch_component_template.package_index_component[each.key].name] : []),
    [elasticstack_elasticsearch_component_template.custom_index_component[each.key].name]
  )

  data_stream {
    allow_custom_routing = false
    hidden               = false
  }

  template {
    mappings = jsonencode({
      "_meta" : {
        "package" : {
          "name" : "kubernetes"
        }
      }
    })
  }

  metadata = jsonencode({
    "description" = "Index template for ${local.application_id} ${each.key}"
  })
}

resource "elasticstack_elasticsearch_data_stream" "data_stream" {
  for_each = local.data_streams
  name     = "${each.value}-${var.target_name}.${var.target_env}"

  // make sure that template is created before the data stream
  depends_on = [
    elasticstack_elasticsearch_index_template.index_template
  ]
}


resource "elasticstack_kibana_data_view" "kibana_data_view" {
  space_id = var.space_id
  data_view = {
    id              = "${replace(var.configuration.displayName, "-", "_")}_${var.target_name}_${var.target_env}"
    name            = "${var.configuration.displayName} ${var.target_name} ${var.target_env}"
    title           = join(",", [for idx in var.configuration.dataView.indexIdentifiers : "${idx}-${var.target_name}.${var.target_env}"])
    time_field_name = "@timestamp"

    runtime_field_map = length(local.runtime_fields) != 0 ? local.runtime_fields : null
  }
}

resource "elasticstack_kibana_data_view" "kibana_apm_data_view" {
  space_id = var.space_id
  data_view = {
    id              = "apm_${local.application_id}"
    name            = "APM ${local.application_id}"
    title           = length(var.configuration.apmDataView.indexIdentifiers) > 0 ? join(",", [for i in var.configuration.apmDataView.indexIdentifiers : "traces-apm*${i}*,apm-*${i}*,traces-*${i}*.otel-*,logs-apm*${i}*,apm-*${i}*,logs-*${i}*.otel-*,metrics-apm*${i}*,apm-*${i}*,metrics-*${i}*.otel-*"]) : "traces-apm*,apm-*,traces-*.otel-*,logs-apm*,apm-*,logs-*.otel-*,metrics-apm*,apm-*,metrics-*.otel-*"
    time_field_name = "@timestamp"
  }
}


resource "elasticstack_kibana_import_saved_objects" "dashboard" {
  for_each   = local.dashboards
  depends_on = [elasticstack_kibana_data_view.kibana_data_view]
  overwrite  = true
  space_id   = var.space_id
  file_contents = templatefile(each.value, {
    data_view     = elasticstack_kibana_data_view.kibana_data_view.data_view.id
    apm_data_view = elasticstack_kibana_data_view.kibana_apm_data_view.data_view.id
  })
}



resource "elasticstack_kibana_import_saved_objects" "query" {
  for_each   = local.queries
  depends_on = [elasticstack_kibana_data_view.kibana_data_view]

  overwrite = true
  space_id  = var.space_id

  file_contents = file(each.value)
}


