module "idh_loader" {
  source = "../01_idh_loader"

  product_name      = var.product_name
  env               = var.env
  idh_resource_tier = var.idh_resource_tier
  idh_resource_type = "subnet"
}


data "azurerm_virtual_network" "vnet" {
  name                = var.virtual_network_name
  resource_group_name = var.resource_group_name
}

data "azurerm_subnet" "subnet" {
  for_each = { for subnet_name in data.azurerm_virtual_network.vnet.subnets : subnet_name => subnet_name }

  name                 = each.value
  virtual_network_name = var.virtual_network_name
  resource_group_name  = var.resource_group_name
}



# this data source generates a new cidr every time it is run
data "external" "subnet_cidr" {
  program = [
    "python3", "${path.module}/subnet_finder.py"
  ]

  query = {
    used_cidrs     = jsonencode([for subnet_name in data.azurerm_virtual_network.vnet.subnets : data.azurerm_subnet.subnet[subnet_name].address_prefix])
    starting_cidr  = data.azurerm_virtual_network.vnet.address_space[0]
    desired_prefix = module.idh_loader.idh_resource_configuration.prefix_length
  }
}

# this resource is used to store the cidr used to create the subnet in the state file
# and change it only when the vnet or the product_name length has changed
resource "terraform_data" "subnet_cidr" {
  input = data.external.subnet_cidr.result.cidr

  # use a new cidr only if the vnet or the product_name length has changed
  triggers_replace = [
    data.azurerm_virtual_network.vnet.address_space[0],
    module.idh_loader.idh_resource_configuration.prefix_length
  ]

  # ignore changes to the cidr value because it is calculated everyrun, even after the subnet has already been created
  lifecycle {
    ignore_changes = [input]
  }
}

#
# Subnet
#
module "subnet" {
  source = "../../subnet"

  name                 = var.name
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.virtual_network_name

  address_prefixes = [terraform_data.subnet_cidr.input]

  delegation = lookup(module.idh_loader.idh_resource_configuration, "delegation", null) != null ? {
    name = "delegation"
    service_delegation = {
      name    = module.idh_loader.idh_resource_configuration.delegation.name
      actions = module.idh_loader.idh_resource_configuration.delegation.actions
    }
  } : null

  private_link_service_network_policies_enabled = module.idh_loader.idh_resource_configuration.private_link_service_network_policies_enabled
  private_endpoint_network_policies             = module.idh_loader.idh_resource_configuration.private_endpoint_network_policies

  service_endpoints = var.service_endpoints
}
