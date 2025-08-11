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

    settings = lookup(each.value.template, "settings", null) != null ? jsonencode(each.value.template.settings) : null
    mappings = lookup(each.value.template, "mappings", null) != null ? jsonencode(each.value.template.mappings) : null
  }

  metadata = jsonencode(lookup(each.value, "_meta", null))
}

resource "elasticstack_elasticsearch_component_template" "package_index_component" {
  for_each = local.index_package_component

  name = "${local.application_id}-${each.key}@package"

  template {

    settings = lookup(each.value.template, "settings", null) != null ? jsonencode(each.value.template.settings) : null
    mappings = lookup(each.value.template, "mappings", null) != null ? jsonencode(each.value.template.mappings) : null
  }

  metadata = jsonencode(lookup(each.value, "_meta", null))
}

resource "elasticstack_elasticsearch_index_template" "index_template" {
  for_each = var.configuration.indexTemplate
  name     = "${local.application_id}-${each.key}-idxtpl"

  priority       = 500
  index_patterns = [for p in each.value.indexPatterns : "${p}-${local.elastic_namespace}"]
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
  name     = "${each.value}-${local.elastic_namespace}"

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
    title           = join(",", [for idx in var.configuration.dataView.indexIdentifiers : "${idx}-${local.elastic_namespace}"])
    time_field_name = "@timestamp"

    runtime_field_map = length(local.runtime_fields) != 0 ? local.runtime_fields : null
  }
}

resource "elasticstack_kibana_data_view" "kibana_apm_data_view" {
  space_id = var.space_id
  data_view = {
    id              = "apm_${local.application_id}"
    name            = "APM ${local.application_id}"
    title           = length(var.configuration.apmDataView.indexIdentifiers) > 0 ? join(",", [for i in var.configuration.apmDataView.indexIdentifiers : "traces-apm*${i}*-${local.elastic_namespace},apm-*${i}*-${local.elastic_namespace},traces-*${i}*.otel-*-${local.elastic_namespace},logs-apm*${i}*-${local.elastic_namespace},apm-*${i}*-${local.elastic_namespace},logs-*${i}*.otel-*,metrics-apm*${i}*-${local.elastic_namespace},apm-*${i}*-${local.elastic_namespace},metrics-*${i}*.otel-*-${local.elastic_namespace}"]) : "traces-apm*-${local.elastic_namespace},apm-*-${local.elastic_namespace},traces-*.otel-*-${local.elastic_namespace},logs-apm*,apm-*-${local.elastic_namespace},logs-*.otel-*-${local.elastic_namespace},metrics-apm*-${local.elastic_namespace},apm-*-${local.elastic_namespace},metrics-*.otel-*-${local.elastic_namespace}"
    time_field_name = "@timestamp"
  }
}


resource "elasticstack_kibana_import_saved_objects" "dashboard" {
  for_each   = local.dashboards
  depends_on = [elasticstack_kibana_data_view.kibana_data_view]
  overwrite  = true
  space_id   = var.space_id
  file_contents = templatefile(each.value, {
    data_view           = elasticstack_kibana_data_view.kibana_data_view.data_view.id
    data_view_name      = elasticstack_kibana_data_view.kibana_data_view.data_view.name
    data_view_title     = elasticstack_kibana_data_view.kibana_data_view.data_view.title
    apm_data_view       = elasticstack_kibana_data_view.kibana_apm_data_view.data_view.id
    apm_data_view_name  = elasticstack_kibana_data_view.kibana_apm_data_view.data_view.name
    apm_data_view_title = elasticstack_kibana_data_view.kibana_apm_data_view.data_view.title
  })
}



resource "elasticstack_kibana_import_saved_objects" "query" {
  for_each   = local.queries
  depends_on = [elasticstack_kibana_data_view.kibana_data_view]

  overwrite = true
  space_id  = var.space_id

  file_contents = file(each.value)
}

resource "elasticstack_kibana_alerting_rule" "alert" {
  for_each = local.alerts

  lifecycle {
    precondition {
      condition     = var.alert_channels.opsgenie.enabled ? contains(keys(var.alert_channels.opsgenie.connectors), lookup(each.value.notification_channels, "opsgenie", { connector_name : "" }).connector_name) : true
      error_message = "opsgenie connector name '${lookup(each.value.notification_channels, "opsgenie", { connector_name : "" }).connector_name}' must be defined in var.app_connectors. used by alert '${each.value.name}' in '${var.application_name}' application"
    }

    precondition {
      condition     = var.alert_channels.slack.enabled ? contains(keys(var.alert_channels.slack.connectors), lookup(each.value.notification_channels, "slack", { connector_name : "" }).connector_name) : true
      error_message = "slack connector name '${lookup(each.value.notification_channels, "slack", { connector_name : "" }).connector_name}' must be defined in var.app_connectors. used by alert '${each.value.name}' in '${var.application_name}' application"
    }

    precondition {
      condition     = var.alert_channels.email.enabled ? contains(keys(var.alert_channels.email.recipients), lookup(each.value.notification_channels, "email", { recipient_list_name : "" }).recipient_list_name) : true
      error_message = "email list name '${lookup(each.value.notification_channels, "email", { recipient_list_name : "" }).recipient_list_name}' must be defined in var.email_recipients. used by alert '${each.value.name}' in '${var.application_name}' application"
    }

    precondition {
      condition     = lookup(each.value, "log_query", null) != null ? lookup(each.value, "apm_metric", null) == null : true
      error_message = "log_query and apm_metric are mutually exclusive. used by alert '${each.value.name}' in '${var.application_name}' application"
    }

    precondition {
      condition     = lookup(each.value, "log_query", null) != null ?  each.value.log_query.aggregation != null && each.value.log_query.query != null && each.value.log_query.data_view != null : true
      error_message = "log_query must have aggregation, query and data_view defined. used by alert '${each.value.name}' in '${var.application_name}' application"
    }

    precondition {
      condition     = lookup(each.value, "log_query", null) != null ?  contains(["logs", "apm"], each.value.log_query.data_view) : true
      error_message = "log_query.data_view type must be either 'logs' or 'apm'. used by alert '${each.value.name}' in '${var.application_name}' application"
    }

    precondition {
      condition     = lookup(each.value, "log_query", null) != null ?  contains(["count", "sum", "avg", "min", "max"], each.value.log_query.aggregation.type) : true
      error_message = "log_query.aggregation.type must be one of 'sum', 'avg', 'min', 'max'. used by alert '${each.value.name}' in '${var.application_name}' application"
    }

    precondition {
      condition     = lookup(each.value, "log_query", null) != null && contains(["sum", "avg", "min", "max"], try(each.value.log_query.aggregation.type, "")) ? try(each.value.log_query.aggregation.field, null) != null : true
      error_message = "log_query.aggregation.field must be defined when aggregation type is 'sum', 'avg', 'min' or 'max'. used by alert '${each.value.name}' in '${var.application_name}' application"
    }

    precondition {
      condition     = lookup(each.value, "apm_metric", null) != null ? lookup(each.value, "log_query", null) == null : true
      error_message = "log_query and apm_metric are mutually exclusive. used by alert '${each.value.name}' in '${var.application_name}' application"
    }

    precondition {
      condition     = lookup(each.value, "apm_metric", null) != null ?  each.value.apm_metric.type != null && each.value.apm_metric.filter != null && each.value.apm_metric.metric != null : true
      error_message = "apm_metric must have type, filter and metric defined. used by alert '${each.value.name}' in '${var.application_name}' application"
    }

    precondition {
      condition     = lookup(each.value, "apm_metric", null) != null ?  contains(["failed_transactions", "latency", "error_count", "anomaly"], each.value.apm_metric.metric) : true
      error_message = "apm_metric.metric must be one of ${join(",", keys(local.rule_type_id_map))}. used by alert '${each.value.name}' in '${var.application_name}' application"
    }


    # when apm_metric is defined, apm_metric.threshold must be defined
    precondition {
      condition     = lookup(each.value, "apm_metric", null) != null ? each.value.apm_metric.threshold != null : true
      error_message = "apm_metric.threshold must be defined when apm_metric is used. used by alert '${each.value.name}' in '${var.application_name}' application"
    }

    precondition {
      condition     = lookup(each.value, "log_query", null) != null ? each.value.log_query.threshold != null : true
      error_message = "log_query.threshold must be defined when log_query is used. used by alert '${each.value.name}' in '${var.application_name}' application"
    }

    precondition {
      condition     = lookup(each.value, "log_query", null) != null ? each.value.log_query.threshold.comparator != null && length(each.value.log_query.threshold.values) > 0 : true
      error_message = "log_query.threshold must have comparator and values defined. used by alert '${each.value.name}' in '${var.application_name}' application"
    }

    precondition {
      condition     = lookup(each.value, "log_query", null) != null ?  contains([">", ">=", "<", "<=", "between", "notBetween"], each.value.log_query.threshold.comparator) : true
      error_message = "log_query.threshold.comparator must be one of '>', '>=', '<', '<=', 'between', 'notBetween'. used by alert '${each.value.name}' in '${var.application_name}' application"
    }

    precondition {
      condition     = lookup(each.value, "log_query", null) != null ? (contains(["between", "notBetween"], each.value.log_query.threshold.comparator) ? length(each.value.log_query.threshold.values) == 2 : length(each.value.log_query.threshold.values) == 1) : true
      error_message = "log_query.threshold.values must be a single value for comparators '>', '>=', '<', '<=', or an array of two values for comparators 'between' or 'notBetween'. used by alert '${each.value.name}' in '${var.application_name}' application"
    }


    # precondition {
    #   condition     = each.value.source_data_view_type == "apm" ? : true
    #   error_message = ""
    #   # latency = apm.transaction_duration
    #   # failed trnsactions = apm.transaction_error_rate
    #   # anomaly = apm.anomaly .    "anomalySeverityType": "critical",
    #   #    "anomalyDetectorTypes": [
    #   #      "txLatency",
    #   #      "txThroughput",
    #   #      "txFailureRate"
    #   #    ]
    #   # error count = apm.error_rate
    # }

  }

  name        = "${local.application_id} ${each.value.name}"
  consumer    = lookup(each.value, "log_query", null) != null ? "logs" : "alerts"
  rule_type_id = lookup(each.value, "log_query", null) != null ? ".es-query" : local.rule_type_id_map[lookup(each.value, "apm_metric", null).metric]
  notify_when = "onActionGroupChange"
  params = jsonencode(
    merge(
      # log query fields
      lookup(each.value, "log_query", null) != null ? {
        searchConfiguration : {
          query : {
            query : each.value.log_query.query
            language : "kuery"
          },
          index : each.value.log_query.data_view == "logs" ? elasticstack_kibana_data_view.kibana_data_view.data_view.id : elasticstack_kibana_data_view.kibana_apm_data_view.data_view.id
        }
        timeField : "@timestamp"
        searchType : "searchSource"
        timeWindowSize : each.value.window.size
        timeWindowUnit : each.value.window.unit
        aggType : each.value.log_query.aggregation.type
        threshold : each.value.log_query.threshold.values
        thresholdComparator : each.value.log_query.threshold.comparator
        groupBy : "all"
      } : null,
      # optional log_query fields
      lookup(lookup(each.value, "log_query", {aggregation: {}}).aggregation, "field", null) != null ? {aggField: lookup(each.value.log_query.aggregation, "field", null)} : null,
      # apm metric fields
      lookup(each.value, "apm_metric", null) != null ? {
        searchConfiguration : {
          query : {
            query : each.value.apm_metric.filter
            language : "kuery"
          }
        }
        useKqlFilter: true
        windowSize: each.value.window.size
        windowUnit: each.value.window.unit
        environment: var.target_env
        threshold : each.value.apm_metric.threshold
      } : null,
      # common parameters for both log_query and apm_metric
      {
        size : 1
        termSize : 5
        excludeHitsFromPreviousRun : each.value.exclude_hits_from_previous_run
      }
    )
  )
  interval     = each.value.schedule

  # manually disabled overrides the default enabled value
  # if at least one channel is enabled, the alert is enabled
  enabled = lookup(each.value, "enabled", true) && (var.alert_channels.email.enabled || var.alert_channels.opsgenie.enabled || var.alert_channels.slack.enabled)
  space_id = var.space_id
  alert_delay = lookup(each.value, "trigger_after_consecutive_runs", null)

  #email
  dynamic "actions" {
    for_each = var.alert_channels.email.enabled && lookup(each.value.notification_channels, "email", { recipient_list_name : "" }).recipient_list_name != "" ? [1] : []
    content {
      id = "elastic-cloud-email"
      params = jsonencode({
        message = local.alert_message
        to      = var.alert_channels.email.recipients[each.value.notification_channels.email.recipient_list_name],
        cc      = []
        subject = "Elastic alert ${var.target_env} ${each.value.name}"
      })
      frequency {
        notify_when = "onActionGroupChange"
        summary     = false
      }
    }
  }

  #email close
  dynamic "actions" {
    for_each = var.alert_channels.email.enabled && lookup(each.value.notification_channels, "email", { recipient_list_name : "" }).recipient_list_name != "" ? [1] : []
    content {
      group = "recovered"
      id    = "elastic-cloud-email"
      params = jsonencode({
        message = "Recovered - ${var.target_env} ${each.value.name}"
        to      = var.alert_channels.email.recipients[each.value.notification_channels.email.recipient_list_name],
        cc      = []
        subject = "Recovered - Elastic alert ${var.target_env} ${each.value.name}"
      })
      frequency {
        notify_when = "onActionGroupChange"
        summary     = false
      }
    }
  }

  #opsgenie create
  dynamic "actions" {
    for_each = var.alert_channels.opsgenie.enabled && lookup(each.value.notification_channels, "opsgenie", { connector_name : "" }).connector_name != "" ? [1] : []
    content {
      id = var.alert_channels.opsgenie.connectors[each.value.notification_channels.opsgenie.connector_name]
      params = jsonencode({
        subAction = "createAlert"
        subActionParams = {
          alias = "{{rule.id}}:{{alert.id}}"
          tags = [
            "{{rule.tags}}"
          ],
          message     = "Elastic alert ${var.target_env} ${each.value.name}"
          priority    = each.value.notification_channels.opsgenie.priority
          description = local.alert_message
        }
      })
      frequency {
        notify_when = "onActionGroupChange"
        summary     = false
      }
    }
  }

  #opsgenie close alert
  dynamic "actions" {
    for_each = var.alert_channels.opsgenie.enabled && lookup(each.value.notification_channels, "opsgenie", { connector_name : "" }).connector_name != "" ? [1] : []
    content {
      group = "recovered"
      id    = var.alert_channels.opsgenie.connectors[each.value.notification_channels.opsgenie.connector_name]
      params = jsonencode({
        subAction = "closeAlert"
        subActionParams = {
          alias = "{{rule.id}}:{{alert.id}}"
        }
      })
      frequency {
        notify_when = "onActionGroupChange"
        summary     = false
      }
    }
  }

  #slack
  dynamic "actions" {
    for_each = var.alert_channels.slack.enabled && lookup(each.value.notification_channels, "slack", { connector_name : "" }).connector_name != "" ? [1] : []
    content {
      id = var.alert_channels.slack.connectors[each.value.notification_channels.slack.connector_name]
      params = jsonencode({
        "message" : local.alert_message
      })
      frequency {
        notify_when = "onActionGroupChange"
        summary     = false
      }
    }
  }

  #slack close
  dynamic "actions" {
    for_each = var.alert_channels.slack.enabled && lookup(each.value.notification_channels, "slack", { connector_name : "" }).connector_name != "" ? [1] : []
    content {
      group = "recovered"
      id    = var.alert_channels.slack.connectors[each.value.notification_channels.slack.connector_name]
      params = jsonencode({
        "message" : "Recovered - ${var.target_env} ${each.value.name}"
      })
      frequency {
        notify_when = "onActionGroupChange"
        summary     = false
      }
    }
  }
}


