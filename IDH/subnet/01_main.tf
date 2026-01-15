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

# this resource is used to store the first usable ip
# and change it only when the vnet or the product_name length has changed
resource "terraform_data" "subnet_first_ip" {
  input = data.external.subnet_cidr.result.first

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

# this resource is used to store the last usable ip
# and change it only when the vnet or the product_name length has changed
resource "terraform_data" "subnet_last_ip" {
  input = data.external.subnet_cidr.result.last

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

resource "azurerm_resource_group" "nsg_rg" {
  name     = "${var.name}-nsg-rg"
  location = data.azurerm_virtual_network.vnet.location
}

module "embedded_nsg" {
  source = "../../network_security_group"
  count  = can(module.idh_loader.idh_resource_configuration.nsg) ? 1 : 0

  prefix              = var.name
  resource_group_name = azurerm_resource_group.nsg_rg.name
  location            = data.azurerm_virtual_network.vnet.location

  vnets = {
    "${data.azurerm_virtual_network.vnet.name}" = data.azurerm_virtual_network.vnet.resource_group_name
  }

  custom_security_group = {
    embedded = {
      target_subnet_id = module.subnet.subnet_id

      watcher_enabled = true

      inbound_rules = [
        can(module.idh_loader.idh_resource_configuration.nsg.service) ?
        {
          target_service               = module.idh_loader.idh_resource_configuration.nsg.service
          name                         = "Allow${title(var.embedded_nsg_configuration.source_address_prefixes_name)}On${title(module.idh_loader.idh_resource_configuration.nsg.service)}"
          priority                     = 200
          source_address_prefixes      = var.embedded_nsg_configuration.source_address_prefixes
          description                  = "Allow traffic for ${module.idh_loader.idh_resource_configuration.nsg.service} from ${var.embedded_nsg_configuration.source_address_prefixes_name}"
          destination_port_ranges      = null
          destination_address_prefixes = module.subnet.address_prefixes
          protocol                     = null
          } : {
          name                         = "Allow${title(var.embedded_nsg_configuration.source_address_prefixes_name)}"
          priority                     = 200
          protocol                     = module.idh_loader.idh_resource_configuration.nsg.custom.protocol
          source_address_prefixes      = var.embedded_nsg_configuration.source_address_prefixes
          destination_port_ranges      = module.idh_loader.idh_resource_configuration.nsg.custom.ports
          description                  = "Allow traffic from ${var.embedded_nsg_configuration.source_address_prefixes_name}"
          target_service               = null
          destination_address_prefixes = module.subnet.address_prefixes

        },
        {
          name                    = "DenyFromAllVNet"
          priority                = 4090
          destination_port_ranges = ["*"]
          source_address_prefixes = ["*"]
          protocol                = "*"
          description             = "Deny everyone else"
          access                  = "Deny"
        }
      ]
      outbound_rules = []
    }
  }

  flow_logs = var.nsg_flow_log_configuration.enabled ? {
    network_watcher_name       = var.nsg_flow_log_configuration.network_watcher_name
    network_watcher_rg         = var.nsg_flow_log_configuration.network_watcher_rg
    storage_account_id         = var.nsg_flow_log_configuration.storage_account_id
    traffic_analytics_law_name = var.nsg_flow_log_configuration.traffic_analytics_law_name
    traffic_analytics_law_rg   = var.nsg_flow_log_configuration.traffic_analytics_law_rg
  } : null

  tags = var.tags
}


module "custom_nsg" {
  source = "../../network_security_group"
  # forces execution after embedded_nsg. Useful to handle priority conflicts
  depends_on = [module.embedded_nsg]
  count      = var.custom_nsg_configuration != null ? 1 : 0

  prefix              = var.name
  resource_group_name = azurerm_resource_group.nsg_rg.name
  location            = data.azurerm_virtual_network.vnet.location


  vnets = {
    "${var.virtual_network_name}" = var.resource_group_name
  }

  custom_security_group = {
    custom = {
      target_subnet_id = module.subnet.subnet_id
      watcher_enabled  = true

      inbound_rules = [
        try(var.custom_nsg_configuration.target_service, null) != null ? {
          name                         = "Allow${title(var.custom_nsg_configuration.source_address_prefixes_name)}On${title(var.custom_nsg_configuration.target_service)}"
          priority                     = 1000
          protocol                     = null
          source_address_prefixes      = var.custom_nsg_configuration.source_address_prefixes
          destination_port_ranges      = null
          description                  = "Allow traffic from ${var.custom_nsg_configuration.source_address_prefixes_name}"
          destination_address_prefixes = module.subnet.address_prefixes
          target_service               = var.custom_nsg_configuration.target_service
          } : {
          name                         = "Allow${title(var.custom_nsg_configuration.source_address_prefixes_name)}"
          priority                     = 1000
          protocol                     = var.custom_nsg_configuration.protocol
          source_address_prefixes      = var.custom_nsg_configuration.source_address_prefixes
          destination_port_ranges      = var.custom_nsg_configuration.target_ports
          description                  = "Allow traffic from ${var.custom_nsg_configuration.source_address_prefixes_name}"
          destination_address_prefixes = module.subnet.address_prefixes
          target_service               = null
        },
        {
          name                         = "DenyFromAllVNet"
          priority                     = 4090
          destination_port_ranges      = ["*"]
          destination_address_prefixes = module.subnet.address_prefixes
          source_address_prefixes      = ["*"]
          protocol                     = "*"
          description                  = "Deny everyone else"
          access                       = "Deny"
        }
      ]
      outbound_rules = []
    }


  }

  flow_logs = var.nsg_flow_log_configuration.enabled ? {
    network_watcher_name       = var.nsg_flow_log_configuration.network_watcher_name
    network_watcher_rg         = var.nsg_flow_log_configuration.network_watcher_rg
    storage_account_id         = var.nsg_flow_log_configuration.storage_account_id
    traffic_analytics_law_name = var.nsg_flow_log_configuration.traffic_analytics_law_name
    traffic_analytics_law_rg   = var.nsg_flow_log_configuration.traffic_analytics_law_rg
  } : null
  tags = var.tags
}
