variable "prefix" {
  type = string
  description = "(Required) The prefix used to identify the catalog to be used"
  validation {
    condition = (
      length(var.prefix) <= 6
    )
    error_message = "Max length is 6 chars."
  }
}

variable "env" {
  type = string
  description = "(Required) The environment used to identify the catalog to be used"
}

variable "idh_resource" {
  type        = string
  description = "(Required) The IDH resource name to be created"

  validation {
    condition     = can(lookup(local.local_data[var.idh_category], var.idh_resource))
    error_message = "Specified idh resource not available in given category"
  }
}

variable "idh_category" {
  type        = string
  description = "(Required) The IDH resource category to be created."

  validation {
    condition     = can(lookup(local.local_data, var.idh_category))
    error_message = "Specified idh category not available in catalog"
  }
}
