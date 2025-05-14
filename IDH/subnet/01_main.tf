module "idh_loader" {
  source = "../idh_loader"

  prefix        = var.prefix
  env           = var.env
  idh_resource  = var.idh_resource
  idh_category  = "subnet"
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



data "external" "subnet_cidr" {
  program = [
    "python3", "${path.module}/subnet_finder.py"
  ]

  query = {
    used_cidrs = jsonencode([for subnet_name in data.azurerm_virtual_network.vnet.subnets : data.azurerm_subnet.subnet[subnet_name].address_prefix])
    starting_cidr = data.azurerm_virtual_network.vnet.address_space[0]
    desired_prefix = module.idh_loader.idh_config.prefix_length
  }
}



resource "terraform_data" "subnet_cidr" {
  input = data.external.subnet_cidr.result.cidr

  triggers_replace = [
    data.azurerm_virtual_network.vnet.address_space[0],
    module.idh_loader.idh_config.prefix_length
  ]

  lifecycle {
    ignore_changes = [input]
  }
}


module "subnet" {
  source = "../../subnet"

  name = var.name
  resource_group_name = var.resource_group_name
  virtual_network_name = var.virtual_network_name

  address_prefixes = [terraform_data.subnet_cidr.input]


  delegation = lookup(module.idh_loader.idh_config, "delegation", null) != null ? {
    name = "delegation"
    service_delegation = {
      name    = module.idh_loader.idh_config.delegation.name
      actions = module.idh_loader.idh_config.delegation.actions
    }
  } : null


  private_endpoint_network_policies = var.private_endpoint_network_policies
  private_link_service_network_policies_enabled = var.private_link_service_network_policies_enabled
  service_endpoints = var.service_endpoints

}
