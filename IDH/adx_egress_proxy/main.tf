module "idh_loader" {
  source            = "../01_idh_loader"
  product_name      = var.product_name
  env               = var.env
  idh_resource_tier = var.idh_resource_tier
  idh_resource_type = "aks_node_pool"
}


module "vmss_snet" {
  source               = "./.terraform/modules/__v4__/IDH/subnet"
  name                 = "${var.name}-vmss-snet"
  resource_group_name  = var.vnet.resource_group_name
  virtual_network_name = var.vnet.name

  idh_resource_tier = "slash28_privatelink_true"
  product_name      = var.product_name
  env               = var.env

  service_endpoints = [
    "Microsoft.AzureCosmosDB"
  ]

  tags = var.tags

}

resource "azurerm_subnet_nat_gateway_association" "vmss_snet_nat" {
  count = var.nat_gateway != null ? 1 : 0
  subnet_id      = module.vmss_snet.id
  nat_gateway_id = data.azurerm_nat_gateway.nat_gateway[0].id
}

module "vmss_pls_snet" {
  source               = "./.terraform/modules/__v4__/IDH/subnet"
  name                 = "${var.name}-pls-snet"
  resource_group_name  = var.vnet.resource_group_name
  virtual_network_name = var.vnet.name

  idh_resource_tier = "slash28_privatelink_false"
  product_name      = var.product_name
  env               = var.env

  tags = var.tags
}



#
# create load balancer (NVA) with tcp/0 ports
#
module "load_balancer_observ_egress" {
  source = "./.terraform/modules/__v4__/load_balancer"

  resource_group_name                    = local.vnet_core_resource_group_name
  location                               = var.location
  name                                   = "${var.name}-egress-lb"
  frontend_name                          = "frontend_private_ip"
  type                                   = "private"
  frontend_subnet_id                     = module.vmss_snet.id
  frontend_private_ip_address_allocation = "Static"
  frontend_private_ip_address            = module.vmss_snet.last_ip_address
  lb_sku                                 = "Standard"
  pip_sku                                = "Standard"
  lb_port = {
    lb_network = {
      frontend_port     = "0"
      protocol          = "All"
      backend_port      = "0"
      backend_pool_name = "default"
      probe_name        = "probe_ssh"
    }
  }

  lb_probe = {
    probe_ssh = {
      protocol     = "Tcp"
      port         = "22"
      request_path = ""
    }
  }

  tags = var.tags

  depends_on = []
}

resource "azurerm_linux_virtual_machine_scale_set" "vmss-egress" {
  name                            = "${var.name}-vmss"
  resource_group_name             = var.vmss_resource_group_name
  location                        = data.azurerm_resource_group.vmss_rg.location
  sku                             = var.vmss_size
  instances                       = 1
  admin_username                  = var.vmss_credentials.admin_login
  admin_password                  = var.vmss_credentials.admin_password
  disable_password_authentication = false
  zones                           = ["1"]

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
    disk_size_gb         = 128
  }

  network_interface {
    name                          = "egress-input"
    primary                       = true
    enable_ip_forwarding          = true
    enable_accelerated_networking = true

    ip_configuration {
      name                                   = "egress-in"
      primary                                = true
      subnet_id                              = module.vmss_snet.id
      load_balancer_backend_address_pool_ids = [module.load_balancer_observ_egress.azurerm_lb_backend_address_pool_id[0]]
    }
  }
  network_interface {
    name                          = "egress-output"
    enable_ip_forwarding          = true
    enable_accelerated_networking = true
    ip_configuration {
      name      = "egress-out"
      primary   = true
      subnet_id = module.vmss_snet.id
    }
  }
}





resource "azurerm_monitor_autoscale_setting" "vmss_scale" {
  count               = module.idh_loader.idh_resource_configuration.vmss_scale_enabled ? 1 : 0
  name                = "${var.name}-vmss-scale"
  resource_group_name = var.vmss_resource_group_name
  location            = data.azurerm_resource_group.vmss_rg.location
  target_resource_id  = azurerm_linux_virtual_machine_scale_set.vmss-egress.id

  profile {
    name = "${var.name}-vmss-scale-rule-cpu"

    capacity {
      default = 1
      minimum = 1
      maximum = 3
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.vmss-egress.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 75
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT1M"
      }
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.vmss-egress.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = 20
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT1M"
      }
    }
  }

}


#
# vmss extension script network-config.sh
# N.B. vmss with private load balancer lost internet connection. script embedded in base64
#
resource "azurerm_virtual_machine_scale_set_extension" "vmss-extension" {
  name                         = "network-rule-forward"
  virtual_machine_scale_set_id = azurerm_linux_virtual_machine_scale_set.vmss-egress.id
  publisher                    = "Microsoft.Azure.Extensions"
  type                         = "CustomScript"
  type_handler_version         = "2.1"
  settings = jsonencode({
    "script" : "${local.base64_script}"
  })
}


resource "azurerm_key_vault_secret" "database_map_secret" {
  name         = "${var.name}-database-map"
  value        = join(",", local.postgres_fqdn_map[*].db_fqdn)
  content_type = "text/plain"

  key_vault_id = data.azurerm_key_vault.kv_domain.id
}



resource "azurerm_private_link_service" "vmss_pls" {
  name                = "${var.name}-privatelink"
  resource_group_name = var.vmss_resource_group_name
  location            = data.azurerm_resource_group.vmss_rg.location

  auto_approval_subscription_ids              = [data.azurerm_client_config.current.subscription_id]
  visibility_subscription_ids                 = [data.azurerm_client_config.current.subscription_id]
  load_balancer_frontend_ip_configuration_ids = [module.load_balancer_observ_egress.azurerm_lb_frontend_ip_configuration[0].id]

  nat_ip_configuration {
    name                       = "primary"
    private_ip_address         = module.vmss_pls_snet.last_ip_address
    private_ip_address_version = "IPv4"
    subnet_id                  = module.vmss_pls_snet.id
    primary                    = true
  }
}
