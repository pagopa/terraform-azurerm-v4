
###############################################################################
# Variables
###############################################################################

variable "aks_cluster_name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "environment" {
  type    = string
  default = "production"
}

variable "static_lb_ip" {
  description = "Pre-allocated static IP in the subnet for the internal Load Balancer."
  type        = string
  default     = null
}

variable "lb_subnet_name" {
  description = "Name of the Azure subnet dedicated to the internal Load Balancer."
  type        = string
  default     = ""
}
