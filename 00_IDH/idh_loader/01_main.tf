locals {
  # local_data = jsondecode(file("${path.module}/../idh/${var.prefix}/${var.env}/idh.json"))
  local_data = yamldecode(file("${path.module}/../idh/${var.prefix}/${var.env}/idh.yml"))
}



