resource "random_id" "unique" {
  byte_length = 3
}

locals {
  project = "${var.prefix}${random_id.unique.hex}"
}
