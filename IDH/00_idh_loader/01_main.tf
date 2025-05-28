locals {
  local_data = yamldecode(file("${path.module}/../00_idh/${var.prefix}/${var.env}/${var.idh_category}.yml"))

  envs = ["dev", "uat", "prod"]
}



