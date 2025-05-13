locals {
  local_data = jsondecode(file("${path.module}/../idh/${var.prefix}/${var.env}/idh.json"))
}



