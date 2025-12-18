locals {
  platform_env_tiers_configuration = try(yamldecode(file("${path.module}/../00_product_configs/${var.product_name}/${var.env}/${var.idh_resource_type}.yml")), {})
  platform_common_tiers_configuration = try(yamldecode(file("${path.module}/../00_product_configs/${var.product_name}/common/${var.idh_resource_type}.yml")), {})
  global_common_tiers_configuration = try(yamldecode(file("${path.module}/../00_product_configs/common/${var.idh_resource_type}.yml")), {})

  tiers_configurations = merge(
    local.global_common_tiers_configuration,
    local.platform_common_tiers_configuration,
    local.platform_env_tiers_configuration
  )

  envs = ["dev", "uat", "prod"]
}



