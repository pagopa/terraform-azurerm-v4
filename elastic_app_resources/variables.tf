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


variable "primary_shard_count" {
  type = number
  description = "Number of primary shard for the index templates"
}
