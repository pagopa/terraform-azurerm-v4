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

variable "idh_resource_tier" {
  type        = string
  description = "(Required) The IDH resource tier name choosen for the resource to be created."

  validation {
    condition     = can(lookup(local.tiers_configurations, var.idh_resource_tier))
    error_message = "Specified idh_resource_tier '${var.idh_resource_tier}' not available in catalog for given product_name: '${var.product_name}', env: '${var.env}', idh_resource_type: '${var.idh_resource_type}'"
  }
}

variable "idh_resource_type" {
  type        = string
  description = "(Required) The IDH resource category to be created."

  validation {
    condition     = can(file("${path.module}/../00_product_configs/${var.product_name}/${var.env}/${var.idh_resource_type}.yml")) || can(file("${path.module}/../00_product_configs/common/${var.idh_resource_type}.yml")) || can(file("${path.module}/../00_product_configs/${var.product_name}/common/${var.idh_resource_type}.yml"))
    error_message = "Specified idh_resource_type '${var.idh_resource_type}' not available in catalog for given product_name: '${var.product_name}' and env: '${var.env}'"
  }

}
