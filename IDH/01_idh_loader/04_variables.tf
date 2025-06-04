variable "product_name" {
  type        = string
  description = "(Required) The product_name used to identify the catalog to be used"
  validation {
    condition = (
      length(var.product_name) <= 6
    )
    error_message = "Max length is 6 chars."
  }
}

variable "env" {
  type        = string
  description = "(Required) The environment used to identify the catalog to be used"
  validation {
    condition     = contains(local.envs, var.env)
    error_message = "env must be one of dev, uat, prod"
  }
}

variable "idh_resource" {
  type        = string
  description = "(Required) The IDH resource name to be created"

  validation {
    condition     = can(lookup(local.local_data, var.idh_resource))
    error_message = "Specified idh_resource '${var.idh_resource}' not available in catalog for given product_name: '${var.product_name}', env: '${var.env}', idh_category: '${var.idh_category}'"
  }
}

variable "idh_category" {
  type        = string
  description = "(Required) The IDH resource category to be created."

  validation {
    condition     = can(file("${path.module}/../00_product_configs/${var.product_name}/${var.env}/${var.idh_category}.yml"))
    error_message = "Specified idh_category '${var.idh_category}' not available in catalog for given product_name: '${var.product_name}' and env: '${var.env}'"
  }

}
