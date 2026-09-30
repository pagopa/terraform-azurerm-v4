variable "target_name" {
  type = string
  validation {
    condition = (
      length(var.target_name) <= 6
    )
    error_message = "Max length is 6 chars."
  }

  description = "Name of the monitored target containing this application. eg: pagopa, cstar, p4pa"
}

variable "configuration" {
  type = object({
    displayName = string
    indexTemplate = map(object({
      indexPatterns    = list(string)
      customComponent  = optional(string, null)
      packageComponent = optional(string, null)
      ingestPipeline   = string
    }))
    dataStream = list(string)
    dataView = object({
      indexIdentifiers = list(string)
      runtimeFields    = optional(list(any), [])
    })
    apmDataView = optional(object({
      indexIdentifiers = list(string)
      }), {
      indexIdentifiers = []
    })

  })

  description = "Configuration for this application"
}


variable "space_id" {
  type        = string
  description = "Kibana space identifier where to create the data views and dashboards for this application"
}

variable "space_name" {
  type        = string
  description = "Kibana space name where to create the data views and dashboards for this application. Used in resources display name"
}

variable "target_env" {
  type        = string
  description = "Name of the monitored target environment containing this application"
}

variable "query_folder" {
  type        = string
  description = "Path to the query containing folder for this application"
}

variable "alert_folder" {
  type        = string
  description = "Path to the alert containing folder for this application"
}

variable "dashboard_folder" {
  type        = string
  description = "Path to the dashboard containing folder for this application"

}

variable "library_index_custom_path" {
  type        = string
  description = "Path to the library folder of @custom index components"

}

variable "library_index_package_path" {
  type        = string
  description = "Path to the library folder of @package index components"

}

variable "ilm_name" {
  type        = string
  description = "Name of the ilm to be used for this application indexes (must already exist)"
}

variable "library_ingest_pipeline_path" {
  type        = string
  description = "Path to the library folder of ingestion pipelines"

}

variable "default_custom_component_name" {
  type        = string
  description = "Name of the default @custom index component to be used if none is defined in this app configuration"
}


variable "application_name" {
  type        = string
  description = "Name of this application"
}


variable "custom_index_component_parameters" {
  type        = map(string)
  description = "Additional parameters to be used in the index component templates. The key is the parameter name, the value is the parameter value"
  default     = {}

  validation {
    condition     = alltrue([for k in keys(var.custom_index_component_parameters) : !contains(["name", "pipeline", "lifecycle"], k)])
    error_message = "Parameters 'name', 'pipeline' and 'lifecycle' are reserved and cannot be used in custom_index_component_parameters."
  }
}

variable "alert_channels" {
  type = object({
    email = optional(object({
      enabled    = bool
      recipients = map(list(string))
      }), {
      enabled    = false
      recipients = {}
    })
    slack = optional(object({
      enabled    = bool
      connectors = map(string)
      }), {
      enabled    = false
      connectors = {}
    })
    jsm = optional(object({
      enabled    = bool
      connectors = map(string)
      }), {
      enabled    = false
      connectors = {}
    })
    cloudo = optional(object({
      enabled    = bool
      connectors = map(string)
      }), {
      enabled    = false
      connectors = {}
    })
  })

  description = "Configuration for alert channels to be used in the application alerts. Each channel can be enabled or disabled, and if enabled, must have the necessary recipients or connectors defined."
  default = {
    email = {
      enabled    = false
      recipients = {}
    }
    slack = {
      enabled    = false
      connectors = {}
    }
    jsm = {
      enabled    = false
      connectors = {}
    }
    cloudo = {
      enabled    = false
      connectors = {}
    }
  }

  validation {
    condition     = var.alert_channels.email.enabled == false || length(var.alert_channels.email.recipients) > 0
    error_message = "Email recipients must be defined if email alert channel is enabled."
  }
  validation {
    condition     = var.alert_channels.slack.enabled == false || length(var.alert_channels.slack.connectors) > 0
    error_message = "Slack connectors must be defined if slack alert channel is enabled."
  }
  validation {
    condition     = var.alert_channels.jsm.enabled == false || length(var.alert_channels.jsm.connectors) > 0
    error_message = "JSM connectors must be defined if jsm alert channel is enabled."
  }
  validation {
    condition     = var.alert_channels.cloudo.enabled == false || length(var.alert_channels.cloudo.connectors) > 0
    error_message = "ClouDO connectors must be defined if clouDO alert channel is enabled."
  }
}

variable "system_alert_channels" {
  type = object({
    email = optional(object({
      enabled    = bool
      recipients = map(list(string))
      }), {
      enabled    = false
      recipients = {}
    })
    slack = optional(object({
      enabled    = bool
      connectors = map(string)
      }), {
      enabled    = false
      connectors = {}
    })
    jsm = optional(object({
      enabled    = bool
      connectors = map(string)
      }), {
      enabled    = false
      connectors = {}
    })
    cloudo = optional(object({
      enabled    = bool
      connectors = map(string)
      }), {
      enabled    = false
      connectors = {}
    })
  })

  description = "Configuration for alert channels to be used in the embedded system alerts. Each channel can be enabled or disabled, and if enabled, must have the necessary recipients or connectors defined."
  default = {
    email = {
      enabled    = false
      recipients = {}
    }
    slack = {
      enabled    = false
      connectors = {}
    }
    jsm = {
      enabled    = false
      connectors = {}
    }
    cloudo = {
      enabled    = false
      connectors = {}
    }
  }

  validation {
    condition     = var.system_alert_channels.email.enabled == false || length(var.system_alert_channels.email.recipients) > 0
    error_message = "Email recipients must be defined if email alert channel is enabled."
  }
  validation {
    condition     = var.system_alert_channels.slack.enabled == false || length(var.system_alert_channels.slack.connectors) > 0
    error_message = "Slack connectors must be defined if slack alert channel is enabled."
  }
  validation {
    condition     = var.system_alert_channels.jsm.enabled == false || length(var.system_alert_channels.jsm.connectors) > 0
    error_message = "JSM connectors must be defined if jsm alert channel is enabled."
  }
  validation {
    condition     = var.system_alert_channels.cloudo.enabled == false || length(var.system_alert_channels.cloudo.connectors) > 0
    error_message = "ClouDO connectors must be defined if clouDO alert channel is enabled."
  }
}

variable "system_alert" {
  type = object({
    overlog = optional(object({
      window_size_hours         = optional(number, 1)  # time window to evaluate the overlog alert on
      lookback_comparison_hours = optional(number, 24) # compoare the current time window to the previous time window shifted this many hours back in time
      threshold_percentage      = optional(number, 20) # max allowed increase in log volume between the current time window and the previous time window
      }), {
      window_size_hours         = 1
      lookback_comparison_hours = 24
      threshold_percentage      = 20
    })
    notification_channels = object({ # defines the notification channels to be used for embedded system alerts. At least one channel must be defined.
      email = optional(object({
        recipient_list_name = string
      }), null)
      slack = optional(object({
        connector_name = string
      }), null)
      jsm = optional(object({
        connector_name = string
        priority       = string
      }), null)
    })
  })

  description = "Configuration for embedded system alerts."

  validation {
    condition     = var.system_alert.notification_channels.email != null || var.system_alert.notification_channels.slack != null || var.system_alert.notification_channels.jsm != null
    error_message = "At least one notification channel must be defined for embedded system alerts."
  }
}
