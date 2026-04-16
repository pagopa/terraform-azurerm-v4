locals {
  packer_application_name = "${var.prefix}-packer-dnsforwarder-app"
  target_image_name       = "${var.image_name}-${var.image_version}"
  target_image_id         = "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.Compute/images/${local.target_image_name}"
}
