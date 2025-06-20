variable "tags" {
  type = map(any)
}

variable "resource_group_name" {
  type        = string
  description = "(Required) Name of the resource group in which the function and its related components are created"
}

variable "prefix" {
  type        = string
  description = "(Required) Prefix for dedicated resource names"
}

variable "location" {
  type        = string
  description = "(Required) Resource location"
}

variable "trigger" {
  type = object({
    interval  = number
    frequency = string
  })
  description = "(required) Trigger configuration for the Logic App"

  validation {
    condition     = var.trigger.frequency != "Second"
    error_message = "Seconds trigger not supported, use Minutes or higher."
  }
}

variable "storage_account_settings" {
  type = object({
    name       = string
    table_name = string
    access_key = string
  })
  description = "(Required) Storage account settings for the Logic App"
}

variable "slack_webhook_url" {
  type        = string
  description = "(Required) Slack webhook URL for notifications"

}
