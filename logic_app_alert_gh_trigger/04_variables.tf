variable "name" {
  type        = string
  description = "(Required) The name of the Logic App Workflow."
}

variable "env" {
  type        = string
  description = "(Required) The environment where the Logic App Workflow should be deployed."
}


variable "resource_group_name" {
  type        = string
  description = "(Required) The name of the resource group in which to create the Logic App Workflow."
}

variable "location" {
  type        = string
  description = "(Required) The location where the Logic App Workflow should be created."
}

variable "tags" {
  type        = map(string)
  description = "(Optional) A mapping of tags to assign to the Logic App Workflow."
  default     = {}
}

variable "workflow" {
  type = object({
    workflow_parameters = optional(map(string), {})
    workflow_schema     = optional(string)
    workflow_version    = optional(string)
  })
  default = {
    workflow_parameters = {}
    workflow_schema     = "https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#"
    workflow_version    = "1.0.0.0"
  }
  description = "(Optional) Specify the workflow input parameters and schema version to use."
}


variable "github" {
  type = object({
    org        = string
    repository = string
    pat        = string
  })
  description = "(Required) GitHub organization and repository configuration for the workflow trigger."
  validation {
    condition     = length(var.github.org) > 0 && length(var.github.repository) > 0 && length(var.github.pat) > 0
    error_message = "Both GitHub organization, repository and pat must be provided."
  }
}

variable "event_type" {
  type        = string
  description = "(Required) The type of event to dispatch to GitHub repository."
  default     = "azure-alert"
}


variable "create_identity" {
  type        = bool
  default     = false
  description = "(Optional) Whether to create a User-assigned managed identity for the Logic App Workflow."
}
