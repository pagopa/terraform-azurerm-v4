variable "product" {
  description = "Nome del prodotto, usato per il naming delle risorse (es. local.product)."
  type        = string
}

variable "project" {
  description = "Nome del progetto, usato per il naming dell'ACR di backup (es. local.project)."
  type        = string
}

variable "location" {
  description = "Region Azure in cui creare le risorse."
  type        = string
}

variable "env_short" {
  description = "Sigla ambiente"
  type        = string
}

variable "tags" {
  description = "Tag da applicare a tutte le risorse create dal modulo."
  type        = map(string)
  default     = {}
}

# --- ACR sorgente (esterno al modulo) ---

variable "build_sync_image" {
  description = "Se true, esegue `az acr build` per buildare e pubblicare l'immagine del job di sync "
  type        = bool
  default     = false
}

variable "build_context_path" {
  description = "Path locale (relativo o assoluto) del build context (Dockerfile + sorgenti) dell'immagine del job di sync"
  type        = string
  default     = "build"
}

variable "build_dockerfile" {
  description = "Path del Dockerfile, relativo a build_context_path."
  type        = string
  default     = "Dockerfile"
}

variable "build_platform" {
  description = "Piattaforma target per `az acr build` (es. \"linux\", \"linux/amd64\", \"windows\")."
  type        = string
  default     = "linux"
}

variable "source_acr_id" {
  description = "Resource ID dell'ACR sorgente da cui sincronizzare le immagini (es. module.container_registry_ita.id)."
  type        = string
}

variable "source_acr_login_server" {
  description = "Login server dell'ACR sorgente, es. \"myacrname.azurecr.io\" (tipicamente <nome_acr>.azurecr.io)."
  type        = string
}

variable "source_acr_name" {
  description = "Nome (non login server) dell'ACR sorgente. Richiesto solo se build_sync_image = true, per eseguire `az acr build --registry <name>`."
  type        = string
  default     = null
}

# --- Container App Environment (esterno al modulo) ---

variable "container_app_environment_id" {
  description = "ID del Container App Environment su cui creare il Container App Job."
  type        = string
}

# --- Container App Job ---

variable "image_name" {
  description = "Nome/tag dell'immagine dello job di sync, relativa all'ACR sorgente (es. \"acr-backup-sync:1.0\")."
  type        = string
  default     = "acr-backup-sync:1.0"
}

variable "cron_expression" {
  description = "Espressione cron per lo schedule trigger del job."
  type        = string
  default     = "0 3 * * *"
}

variable "replica_timeout_in_seconds" {
  description = "Timeout in secondi per la replica del job."
  type        = number
  default     = 3600
}

variable "replica_retry_limit" {
  description = "Numero massimo di retry per la replica del job."
  type        = number
  default     = 1
}

variable "cpu" {
  description = "CPU allocata al container del job."
  type        = number
  default     = 0.5
}

variable "memory" {
  description = "Memoria allocata al container del job (es. \"1Gi\")."
  type        = string
  default     = "1Gi"
}
