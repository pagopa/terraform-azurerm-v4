locals {
  local_data = yamldecode(file("${path.module}/../00_product_configs/${var.prefix}/${var.env}/${var.idh_category}.yml"))

  envs = ["dev", "uat", "prod"]
}



