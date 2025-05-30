variable "location" {
  type        = string
  default     = "westeurope"
  description = "(Optional) Specifies the supported Azure location where the resource exists. Changing this forces a new resource to be created."
}

variable "name" {
  type        = string
  description = "(Required) The name of the Linux Virtual Machine Scale Set. Changing this forces a new resource to be created."
}

variable "subscription_id" {
  type        = string
  description = "(Required) Azure subscription id"
}

variable "resource_group_name" {
  type        = string
  description = "(Required) The name of the Resource Group in which the Linux Virtual Machine Scale Set should be exist. Changing this forces a new resource to be created."
}

variable "image_resource_group_name" {
  type        = string
  default     = null
  description = "(Optional) Resource group name where to find the vm image used for azdo vms. If not defined, 'resource_group_name' will be used"
}

variable "source_image_name" {
  type        = string
  description = "(Optional) The name of an Image which each Virtual Machine in this Scale Set should be based on. It must be stored in the same subscription & resource group of this resource"
}

# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_virtual_machine_scale_set#source_image_reference
variable "image_reference" {
  type = object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
  })
  description = "(Optional) A source_image_reference block as defined below."
  default = {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
}

variable "image_type" {
  type        = string
  description = "(Required) Defines the source image to be used, whether 'custom' or 'standard'. `custom` requires `source_image_name` to be defined, `standard` requires `image_reference`"
  default     = "custom"

  validation {
    condition     = contains(["standard", "custom"], var.image_type)
    error_message = "Allowed values for `image_type` are 'custom' or 'standard'"
  }
}

variable "vmss_instances" {
  type        = number
  description = "(Optional) The number of Virtual Machines in the Scale Set. Defaults to 0."
  default     = "0"
}

variable "vm_sku" {
  type        = string
  description = "(Optional) Size of VMs in the scale set. Default to Standard_B1s. See https://azure.microsoft.com/pricing/details/virtual-machines/ for size info."
  default     = "Standard_B2ms"
}

variable "storage_sku" {
  type        = string
  description = "(Optional) The SKU of the storage account with which to persist VM. Use a singular sku that would be applied across all disks, or specify individual disks. Usage: [--storage-sku SKU | --storage-sku ID=SKU ID=SKU ID=SKU...], where each ID is os or a 0-indexed lun. Allowed values: Standard_LRS, Premium_LRS, StandardSSD_LRS, UltraSSD_LRS, Premium_ZRS, StandardSSD_ZRS."
  default     = "StandardSSD_LRS"
}

variable "authentication_type" {
  type        = string
  description = "(Required) Type of authentication to use with the VM. Defaults to password for Windows and SSH public key for Linux. all enables both ssh and password authentication."
  default     = "SSH"
  validation {
    condition = (
      var.authentication_type == "SSH" ||
      var.authentication_type == "PASSWORD" ||
      var.authentication_type == "ALL"
    )
    error_message = "Error: authentication_type can be SSH, PASSWORD or ALL."
  }
}

variable "subnet_id" {
  type        = string
  description = "(Required) An existing subnet ID"
  default     = null
}

variable "encryption_set_id" {
  type        = string
  description = "(Optional) An existing encryption set"
  default     = null
}

variable "admin_password" {
  type        = string
  description = "(Optional) The Password which should be used for the local-administrator on this Virtual Machine. Changing this forces a new resource to be created. will be stored in the raw state as plain-text"
  default     = null
}

variable "zones" {
  type        = list(string)
  description = "(Optional) List of AZ on which the scale set will distribute its instances"
  default     = null
}

variable "zone_balance" {
  type        = bool
  default     = false
  description = "(Optional) If true forces the even distribution of instances across all the configured zones ('zones' variable)"
}

variable "scale_in_rule" {
  type        = string
  description = "(Optional) The scale in rule to use for the VMSS. See https://learn.microsoft.com/en-us/azure/virtual-machine-scale-sets/virtual-machine-scale-sets-autoscale#scale-in-rules for more information"
  default     = null
}

variable "force_deletion_enabled" {
  type        = string
  description = "(Optional) Should the virtual machines chosen for removal be force deleted when the virtual machine scale set is being scaled-in? Possible values are true or false"
  default     = null
}

variable "tags" {
  type        = map(any)
  description = "Tags"
  default     = {}
}

