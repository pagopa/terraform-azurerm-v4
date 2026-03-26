variable "name" {
  type        = string
  description = "The name of the Kubernetes namespace to be created."
}

variable "ad_group_ids" {
  type        = list(string)
  description = "A list of Active Directory id to be granted RBAC permissions within the namespace."
}