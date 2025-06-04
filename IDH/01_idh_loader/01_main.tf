locals {
  local_data = yamldecode(file("${path.module}/../00_product_configs/${var.product_name}/${var.env}/${var.idh_category}.yml"))

  envs = ["dev", "uat", "prod"]
}



