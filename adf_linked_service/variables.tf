variable "env_short" {
  type = string
  description = "(Required): Short environment name (e.g., 'd', 'u', 'p')."

  validation {
    condition = (
      length(var.env_short) == 1
    )
    error_message = "Length must be 1 chars."
  }
}

variable "data_factory_id" {
  type = string
  description = "(Required): The ID of the Azure Data Factory instance to which the managed private endpoint will be associated."
}

variable "data_factory_principal_id" {
  type = string
  description = "(Required): The principal ID of the Azure Data Factory instance to which the managed private endpoint will be associated."
}

# Configurazione dei Linked Services per Azure PostgreSQL in Azure Data Factory.
# Ogni entry definisce una connessione verso un database PostgreSQL specifico,
# con le credenziali e i parametri di connessione recuperati da Azure Key Vault.
# - key_vault_id: ID del Key Vault da cui recuperare i segreti.
# - host_secret_name: nome del segreto contenente l'hostname del server PostgreSQL.
# - port_secret_name: nome del segreto contenente la porta del server PostgreSQL.
# - database_secret_name: nome del segreto contenente il nome del database.
# - username_secret_name: nome del segreto contenente lo username per l'autenticazione.
# - password_secret_name: nome del segreto contenente la password per l'autenticazione.
# es: Cruscotto = {
#        key_vault_id         = data.azurerm_key_vault.cruscotto_kv.id
#        host_secret_name     = "ls-cruscotto-server"
#        port_secret_name     = "ls-cruscotto-port"
#        database_secret_name = "ls-cruscotto-database"
#        username_secret_name = "ls-cruscotto-username"
#        password_secret_name = "ls-cruscotto-password"
#      }
variable "adf_linked_service_postgresql" {
  type = map(object({
    key_vault_id = string #ID del Key Vault da cui recuperare i segreti.
    host_secret_name          = string #nome del segreto contenente l'hostname del server PostgreSQL.
    port_secret_name          = string #nome del segreto contenente la porta del server PostgreSQL.
    database_secret_name      = string #nome del segreto contenente il nome del database.
    username_secret_name      = string #nome del segreto contenente lo username per l'autenticazione.
    password_secret_name      = string #nome del segreto contenente la password per l'autenticazione.
  }))
  description = "(Optional): A map of linked service configurations for PostgreSQL databases. Each entry should contain a connection string and the corresponding database name."
  default = {}
}


# Configurazione dei Linked Services per Azure Cosmos DB in Azure Data Factory.
# Ogni entry definisce una connessione verso un account Cosmos DB specifico.
# - connection_string: connection string dell'account Cosmos DB.
# - database: nome del database Cosmos DB a cui collegarsi.
# es: GpdPayments = {
#      connection_string = data.azurerm_cosmosdb_account.gpd_payments_cosmos_account.primary_sql_connection_string
#      account_name      = data.azurerm_cosmosdb_account.gpd_payments_cosmos_account.name
#      database         = "TablesDb"
#    }
variable "adf_linked_services_cosmosdb" {
  type = map(object({
    connection_string = string #connection string dell'account Cosmos DB.
    account_name      = string #nome dell'account Cosmos DB.
    database          = string #nome del database Cosmos DB a cui collegarsi.
  }))
  description = "(Optional): A map of linked service configurations for Cosmos DB accounts. Each entry should contain a connection string and the corresponding database name."
  default = {}
}

# Configurazione dei Linked Services per Azure Blob Storage in Azure Data Factory.
# Ogni entry definisce una connessione verso un account di archiviazione Blob specifico.
# - connection_string: stringa di connessione all'account di archiviazione Azure Blob Storage.
# es: Test = {
#      connection_string = "asd"
#    }
variable "adf_linked_services_blob" {
  type = map(object({
    connection_string = string #stringa di connessione all'account di archiviazione Azure Blob Storage.
  }))
  description = "(Optional): A map of linked service configurations for Azure Blob Storage accounts. Each entry should contain a connection string."
  default = {}
}
