variable "prefix" {
  description = "Prefix used to identify the platform for which the resource will be created"
  type        = string
}

variable "idh_resource" {
  description = "The name of the IDH resource key to be created."
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources."
  type        = map(string)
  default     = {}
}

variable "permission_type" {
  description = "La tipologia di permesso: admin, developer, external"
  type        = string
}

variable "env" {
  description = "L'environment: dev, prod, uat, etc."
  type        = string
}

variable "key_vault_id" {
  description = "L'ID del Key Vault su cui applicare la policy"
  type        = string
}

variable "tenant_id" {
  description = "Tenant ID di Azure"
  type        = string
}

variable "object_id" {
  description = "Object ID del gruppo o identità a cui assegnare la policy"
  type        = string
}
