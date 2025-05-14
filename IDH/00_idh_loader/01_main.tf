locals {
  file_path = "${path.module}/../00_idh/${var.prefix}/${var.env}/${var.idh_category}.yml"
  local_data = yamldecode(file(local.file_path))
}



