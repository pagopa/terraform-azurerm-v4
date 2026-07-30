# acr-backup-sync

Modulo Terraform che crea:

- un Resource Group dedicato
- un ACR di backup (tramite il modulo `container_registry` interno)
- una User Assigned Identity con `AcrPull`/`Reader` sull'ACR sorgente e `Contributor`/`Reader` sull'ACR di backup
- un `azurerm_container_app_job` schedulato (cron) che esegue la sincronizzazione delle immagini tra i due registry

## Esempio di utilizzo

```hcl
module "acr_backup_sync" {
  source = "./modules/acr-backup-sync"

  product   = local.product
  project   = local.project
  location  = var.location
  env_short = var.env_short

  source_acr_id            = module.container_registry_ita.id
  source_acr_login_server  = "${module.container_registry_ita.name}.azurecr.io"

  container_app_environment_id = azurerm_container_app_environment.tools_cae[0].id

  tags = module.tag_config.tags
}
```

Se vuoi personalizzare lo schedule o le risorse del job:

```hcl
module "acr_backup_sync" {
  source = "./modules/acr-backup-sync"

  product   = local.product
  project   = local.project
  location  = var.location
  env_short = var.env_short

  source_acr_id           = module.container_registry_ita.id
  source_acr_login_server = "${module.container_registry_ita.name}.azurecr.io"

  container_app_environment_id = azurerm_container_app_environment.tools_cae[0].id

  cron_expression = "0 4 * * *"
  image_name      = "acr-backup-sync:1.1"
  cpu             = 1
  memory          = "2Gi"

  tags = module.tag_config.tags
}
```

## Input principali

| Nome | Descrizione | Default |
|---|---|---|
| `product` | Naming prefix generale | — |
| `project` | Naming prefix per l'ACR di backup | — |
| `location` | Region Azure | — |
| `env_short` | Sigla ambiente (SKU/zone redundancy) | — |
| `source_acr_id` | ID dell'ACR sorgente | — |
| `source_acr_login_server` | Login server dell'ACR sorgente | — |
| `container_app_environment_id` | ID del Container App Environment | — |
| `cron_expression` | Cron dello schedule trigger | `"0 3 * * *"` |
| `image_name` | Immagine del job di sync | `"acr-backup-sync:1.0"` |

Vedi `variables.tf` per l'elenco completo.

## Output principali

`backup_acr_id`, `backup_acr_name`, `backup_acr_login_server`, `identity_id`, `identity_principal_id`, `identity_client_id`, `container_app_job_id`, `container_app_job_name`, `resource_group_name`, `resource_group_id`.
