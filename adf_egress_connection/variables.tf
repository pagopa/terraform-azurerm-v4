variable "data_factory_id" {
  type = string
  description = "(Required): The ID of the Azure Data Factory instance to which the managed private endpoint will be associated."
}

variable "egress_proxy_pls_id" {
  type = string
  description = "(Required): The ID of the Private Link Service (PLS) for the egress proxy to which the managed private endpoint will connect."
}

variable "adf_database_mapping" {
  type = string
  description = "(Required): Comma-separated list of FQDNs for the databases that the Azure Data Factory will connect to through the managed private endpoint."
}
