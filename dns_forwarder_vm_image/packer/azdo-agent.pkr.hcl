packer {
  required_plugins {
    azure = {
      version = "<= 2.2.1"
      source  = "github.com/hashicorp/azure"
    }
  }
}

source "azure-arm" "ubuntu" {
  use_azure_cli_auth                = true
  os_type                           = "Linux"
  image_publisher                   = var.base_image_publisher
  image_offer                       = var.base_image_offer
  image_sku                         = var.base_image_sku
  vm_size                           = var.vm_sku

  managed_image_name                = "${var.target_image_name}"
  managed_image_resource_group_name = var.target_resource_group_name

  build_resource_group_name          = var.build_rg_name

  ssh_username                      = "packer"
  ssh_password                      = "password"
  communicator                      = "ssh"
}

build {
  sources = ["azure-arm.ubuntu"]

  provisioner "file" {
    source = "./script-config.sh"
    destination = "/tmp/script-config.sh"
  }

  provisioner "file" {
    source = "./docker-compose.yml"
    destination = "/home/packer/docker-compose.yml"
  }

  provisioner "shell" {
    inline = ["sudo /bin/bash /tmp/script-config.sh"]
  }
}
