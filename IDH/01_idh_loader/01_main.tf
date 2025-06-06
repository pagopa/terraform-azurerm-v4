locals {
  local_data = yamldecode(file("${path.module}/../00_product_configs/${var.product_name}/${var.env}/${var.idh_resource_type}.yml"))

  envs = ["dev", "uat", "prod"]
}



