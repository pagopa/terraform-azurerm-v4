variable "env_short" {
  type        = string
  description = "(Required): Short environment name (e.g., 'd', 'u', 'p')."

  validation {
    condition = (
      length(var.env_short) == 1
    )
    error_message = "Length must be 1 chars."
  }
}

variable "data_factory_id" {
  type        = string
  description = "(Required): The ID of the Azure Data Factory instance to which the managed private endpoint will be associated."
}

variable "data_factory_principal_id" {
  type        = string
  description = "(Required): The principal ID of the Azure Data Factory instance to which the managed private endpoint will be associated."
}

# Configurazione dei Linked Services per Azure PostgreSQL in Azure Data Factory.
# Ogni entry definisce una connessione verso un database PostgreSQL specifico,
# con le credenziali e i parametri di connessione recuperati da Azure Key Vault.
# - key_vault_id: ID del Key Vault da cui recuperare la password di accesso al db.
# - host: hostname raggiungibile privatamente del server PostgreSQL.
# - port: porta del server PostgreSQL.
# - database_name: nome del database PostgreSQL.
# - username: username per l'autenticazione al database PostgreSQL.
# - password_secret_name: nome del segreto contenente la password per l'autenticazione.
# es: IdPay = {
#        key_vault_id         = data.azurerm_key_vault.domain_kv.id
#        host     = "idpay-db.d.internal.postgres.cstar.pagopa.it"
#        port     = "5432"
#        database_name = "idpay-database"
#        username = "myusername"
#        password_secret_name = "idpay-postgres-admin-password"
#      }
variable "adf_linked_service_postgresql" {
  type = map(object({
    key_vault_id         = string #ID del Key Vault da cui recuperare la password di accesso al db.
    host                 = string # hostname raggiungibile privatamente del server PostgreSQL.
    port                 = string # porta del server PostgreSQL.
    database_name        = string # nome del database PostgreSQL.
    username             = string # username per l'autenticazione al database PostgreSQL.
    password_secret_name = string #nome del segreto contenente la password per l'autenticazione.
  }))
  description = "(Optional): A map of linked service configurations for PostgreSQL databases. "
  default     = {}
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
  default     = {}
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
  default     = {}
}


# Configurazione degli endpoint privati gestiti per Azure Data Factory.
  # Ogni entry definisce un endpoint privato verso un servizio specifico tramite Private Link Service.
  # - target_resource_id: ID della risorsa di destinazione.
  # - fqdns: lista di FQDN (Fully Qualified Domain Names) recuperati da Key Vault,
  #          utilizzati per la risoluzione DNS dell'endpoint privato.
  # - subresource_name: nome della sottorisorsa per cui è necessario approvare la connessione (opzionale, dipende dal servizio di destinazione).
  # - type: tipo di risorsa di destinazione, utilizzato per mappare correttamente le API di Azure durante l'approvazione della connessione privata.
  # es:
  # GpdCosmosSql = {
  #    target_resource_id = data.azurerm_cosmosdb_account.gpd_payments_cosmos_account.id
  #    fqdns              = null
  #    subresource_name   = "Sql"
  #    type               = "cosmosdb"
  #  }
  variable "adf_managed_private_endpoint" {
    type = map(object({
      target_resource_id = string #ID della risorsa di destinazione.
      fqdns              = list(string) #lista di FQDN (Fully Qualified Domain Names) recuperati da Key Vault, utilizzati per la risoluzione DNS dell'endpoint privato.
      subresource_name   = string #nome della sottorisorsa per cui è necessario approvare la connessione (opzionale, dipende dal servizio di destinazione).
      type               = string #tipo di risorsa di destinazione, utilizzato per mappare correttamente le API di Azure durante l'approvazione della connessione privata.
    }))
    description = "(Optional): A map of managed private endpoint configurations for Azure Data Factory. Each entry should contain the target resource ID, FQDNs, subresource name, and type."
    default     = {}
  }
