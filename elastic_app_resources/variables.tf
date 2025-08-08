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

variable "email_recipients" {
  type        = map(list(string))
  description = "(Optional) Map of List of email recipients associated to a name. to be used for email alerts. Default is empty"
  default     = {}
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
      enabled     = bool
      connectors  = map(string)
    }), {
      enabled     = false
      connectors  = {}
    })
    opsgenie = optional(object({
      enabled     = bool
      connectors  = map(string)
    }), {
      enabled     = false
      connectors  = {}
    })
  })

  description = "Configuration for alert channels to be used in the application alerts"

  default = {
    email = {
      enabled    = false
      recipients = {}
    }
    slack = {
      enabled     = false
      connectors  = {}
    }
    opsgenie = {
      enabled     = false
      connectors  = {}
    }
  }
}
