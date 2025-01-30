variable "location" {
  type        = string
  description = "The location of the resource group."
}

variable "name" {
  type        = string
  description = "The name of route table"
}

variable "resource_group_name" {
  type = string
}

variable "bgp_route_propagation_enabled" {
  type        = bool
  default     = false
  description = "(Optional) Boolean flag which controls propagation of routes learned by BGP on that route table. Defaults to false."
}

variable "routes" {
  type = list(object({
    name                   = string
    address_prefix         = string
    next_hop_type          = string
    next_hop_in_ip_address = string
  }))
}

variable "subnet_ids" {
  type        = list(string)
  description = "List of ids of subnet to associate to the route table."
}

variable "tags" {
  type = map(any)
}
