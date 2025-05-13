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
    condition     = can(lookup(local.local_data, var.idh_resource))
    error_message = "Specified idh_resource not available in catalog for given prefix, env, idh_category"
  }
}

variable "idh_category" {
  type        = string
  description = "(Required) The IDH resource category to be created."

  validation {
    condition     = can(file("${path.module}/../idh/${var.prefix}/${var.env}/${var.idh_category}.yml"))
    error_message = "Specified idh_category not available in catalog for given prefix and env"
  }

}
