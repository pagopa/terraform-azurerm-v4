# =====================================================================
# ACR Backup Sync Module
# Crea un ACR di backup, un'identity dedicata con i permessi necessari
# e un Container App Job schedulato che sincronizza le immagini
# dall'ACR sorgente verso l'ACR di backup.
# =====================================================================

locals {
  # Hash del build context, usato come trigger per rilanciare `az acr build`
  # solo quando cambia effettivamente qualcosa (Dockerfile o sorgenti).
  build_context_hash = var.build_sync_image ? md5(join("", [
    for f in fileset(var.build_context_path, "**") :
    filesha256("${var.build_context_path}/${f}")
  ])) : null
}

# Build & push opzionale dell'immagine del job di sync sull'ACR sorgente,
# eseguita con `az acr build` nel contesto che lancia `terraform apply`.
resource "terraform_data" "build_sync_image" {
  count = var.build_sync_image ? 1 : 0

  triggers_replace = [
    var.image_name,
    local.build_context_hash,
  ]

  lifecycle {
    precondition {
      condition     = var.source_acr_name != null && var.build_context_path != null
      error_message = "source_acr_name e build_context_path sono obbligatori quando build_sync_image = true."
    }
  }

  provisioner "local-exec" {
    command = "az acr build --registry ${var.source_acr_name} --image ${var.image_name} --file ${var.build_dockerfile} --platform ${var.build_platform} ${var.build_context_path}"
  }
}

resource "azurerm_resource_group" "this" {
  name     = format("%s-container-registry-bck-rg", var.product)
  location = var.location

  tags = var.tags
}

module "container_registry_bck" {
  source = "../container_registry"

  name                           = replace("${var.project}-bck-acr", "-", "")
  sku                            = var.env_short != "d" ? "Premium" : "Basic"
  resource_group_name            = azurerm_resource_group.this.name
  admin_enabled                  = true # TODO: valutare se disabilitare l'admin user
  anonymous_pull_enabled         = false
  zone_redundancy_enabled        = var.env_short != "d" ? true : false
  public_network_access_enabled  = true
  location                       = var.location

  private_endpoint_enabled = false

  network_rule_set = [{
    default_action  = "Allow"
    ip_rule         = []
    virtual_network = []
  }]

  tags = var.tags
}

# Identity dedicata al job, con AcrPull sulla sorgente e permessi sul backup
resource "azurerm_user_assigned_identity" "acr_sync" {
  name                = "${var.product}-acr-backup-sync"
  resource_group_name = azurerm_resource_group.this.name
  location            = var.location

  tags = var.tags
}

resource "azurerm_role_assignment" "pull_source" {
  scope                = var.source_acr_id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.acr_sync.principal_id
}

resource "azurerm_role_assignment" "push_backup" {
  scope                = module.container_registry_bck.id
  role_definition_name = "Contributor" # richiesto per "importImage" action, non disponibile in AcrPush; scope limitato al solo ACR di backup
  principal_id         = azurerm_user_assigned_identity.acr_sync.principal_id
}

resource "azurerm_role_assignment" "reader_source" {
  scope                = var.source_acr_id
  role_definition_name = "Reader"
  principal_id         = azurerm_user_assigned_identity.acr_sync.principal_id
}

resource "azurerm_role_assignment" "reader_backup" {
  scope                = module.container_registry_bck.id
  role_definition_name = "Reader"
  principal_id         = azurerm_user_assigned_identity.acr_sync.principal_id
}

resource "azurerm_container_app_job" "acr_backup_sync" {
  name                          = "${var.product}-caj-acr-backup-sync"
  resource_group_name           = azurerm_resource_group.this.name
  location                      = var.location
  container_app_environment_id  = var.container_app_environment_id

  replica_timeout_in_seconds = var.replica_timeout_in_seconds
  replica_retry_limit        = var.replica_retry_limit

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.acr_sync.id]
  }

  registry {
    server   = var.source_acr_login_server
    identity = azurerm_user_assigned_identity.acr_sync.id
  }

  schedule_trigger_config {
    cron_expression          = var.cron_expression
    parallelism               = 1
    replica_completion_count  = 1
  }

  template {
    container {
      name   = "${var.product}-acr-sync"
      image  = "${var.source_acr_login_server}/${var.image_name}"
      cpu    = var.cpu
      memory = var.memory

      env {
        name  = "SOURCE_ACR"
        value = var.source_acr_login_server
      }
      env {
        name  = "BACKUP_ACR"
        value = "${module.container_registry_bck.name}.azurecr.io"
      }
      env {
        name  = "APPSETTING_WEBSITE_SITE_NAME"
        value = "DUMMY"
      }
      env {
        name  = "MSI_CLIENT_ID"
        value = azurerm_user_assigned_identity.acr_sync.client_id
      }
    }
  }

  tags = var.tags
}
