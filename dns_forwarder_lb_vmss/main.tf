locals {
  prefix                         = "${var.name}-dns-forwarder"
  frontend_private_ip_address_lb = var.static_address_lb != null ? var.static_address_lb : cidrhost(var.address_prefixes_lb, 4)
}

#
# Subnets (Deprecated) generate it outside of this module
#
module "subnet_vmss" {
  source = "../subnet"
  count  = var.create_subnet_vmss ? 1 : 0

  name                 = "${local.prefix}-vmss-snet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.virtual_network_name
  address_prefixes     = [var.address_prefixes_vmss]
}

module "subnet_load_balancer" {
  source = "../subnet"
  count  = var.create_subnet_lb ? 1 : 0

  name                 = "${local.prefix}-lb-snet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.virtual_network_name
  address_prefixes     = [var.address_prefixes_lb]
}

locals {
  subnet_vmss_id = var.subnet_vmss_id != null ? var.subnet_vmss_id : module.subnet_vmss[0].id
  subnet_lb_id   = var.subnet_lb_id != null ? var.subnet_lb_id : module.subnet_load_balancer[0].id
}

#
# NSG
#
resource "azurerm_network_security_group" "vmss" {
  count = var.create_vmss_nsg ? 1 : 0

  name                = "${local.prefix}-vmss-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  security_rule {
    name                       = "${local.prefix}-vmss-dns-load-balancer-rule"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "53"
    destination_port_range     = "53"
    source_address_prefix      = "AzureLoadBalancer"
    destination_address_prefix = "168.63.129.16"
  }

  security_rule {
    name                       = "${local.prefix}-vmss-virtual-network-dns-rule"
    priority                   = 210
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "${local.prefix}-vmss-deny-all-rule"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "vmss" {
  count = var.create_vmss_nsg ? 1 : 0

  subnet_id                 = local.subnet_vmss_id
  network_security_group_id = azurerm_network_security_group.vmss[0].id
}

#
# Load balancer
#
module "load_balancer" {
  source = "../load_balancer"

  name                = "${local.prefix}-internal"
  resource_group_name = var.resource_group_name
  location            = var.location
  lb_sku              = "Standard"
  type                = "private"
  tags                = var.tags

  frontend_name                          = "${local.prefix}-ip-private"
  frontend_private_ip_address_allocation = "Static"
  frontend_private_ip_address            = local.frontend_private_ip_address_lb
  frontend_subnet_id                     = local.subnet_lb_id

  lb_probe = {
    (local.prefix) = {
      protocol     = "Tcp"
      port         = "53"
      request_path = ""
    }
  }

  lb_port = {
    "${local.prefix}-tcp" = {
      frontend_port     = "53"
      protocol          = "Tcp"
      backend_port      = "53"
      backend_pool_name = "${local.prefix}-vmss"
      probe_name        = local.prefix
    }
    "${local.prefix}-udp" = {
      frontend_port     = "53"
      protocol          = "Udp"
      backend_port      = "53"
      backend_pool_name = "${local.prefix}-vmss"
      probe_name        = local.prefix
    }
  }

  lb_backend_pools = [{
    name = "${local.prefix}-vmss"
    ips  = []
  }]
}

#
# VM Scale Set
#
module "vmss" {
  source = "../vm_scale_set"

  name                                   = local.prefix
  resource_group_name                    = var.resource_group_name
  subnet_id                              = local.subnet_vmss_id
  subscription_id                        = var.subscription_id
  location                               = var.location
  source_image_name                      = var.source_image_name
  load_balancer_backend_address_pool_ids = module.load_balancer.azurerm_lb_backend_address_pool_id
  authentication_type                    = "PASSWORD"
  admin_password                         = random_password.psw.result
  vm_sku                                 = var.vm_sku
  storage_sku                            = var.storage_sku
  scale_in_rule                          = var.scale_in_rule
  force_deletion_enabled                 = var.force_deletion_enabled
  tags                                   = var.tags
}

#
# 🔑 Secrets
#
resource "random_password" "psw" {
  length           = 20
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "azurerm_key_vault_secret" "dns_forwarder_vmss_administrator_password" {
  name         = "${local.prefix}-vmss-administrator-password"
  value        = random_password.psw.result
  content_type = "text/plain"
  key_vault_id = var.key_vault_id
  tags         = var.tags
}

resource "azurerm_key_vault_secret" "dns_forwarder_vmss_administrator_username" {
  name         = "${local.prefix}-vmss-administrator-username"
  value        = "adminuser"
  content_type = "text/plain"
  key_vault_id = var.key_vault_id
  tags         = var.tags
}
