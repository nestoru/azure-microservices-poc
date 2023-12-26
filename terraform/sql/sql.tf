# Variable to get the subnet ID from the network module
variable "subnet2_id" {
  description = "The ID of subnet2 in vnet2"
  type        = string
}

# Create an Azure PostgreSQL Server
resource "azurerm_postgresql_server" "postgresql_server" {
  name                = "devops-postgresql-server"
  location            = "francecentral"
  resource_group_name = "devops-microservices"
  sku_name            = "GP_Gen5_2"
  storage_mb          = 5120
  backup_retention_days = 7
  version             = "11"
  administrator_login          = "psqladmin"
  administrator_login_password = "YourPassword123"

  ssl_enforcement_enabled = true
}

# Create an Azure PostgreSQL Database within the Server
resource "azurerm_postgresql_database" "postgresql_db" {
  name                = "devops-postgresql-db"
  resource_group_name = azurerm_postgresql_server.postgresql_server.resource_group_name
  server_name         = azurerm_postgresql_server.postgresql_server.name
  charset             = "UTF8"
  collation           = "English_United States.1252"
}

# Private Endpoint for the PostgreSQL Server
resource "azurerm_private_endpoint" "postgresql_private_endpoint" {
  name                = "postgresql-private-endpoint"
  location            = "francecentral"
  resource_group_name = "devops-microservices"
  subnet_id           = var.subnet2_id

  private_service_connection {
    name                           = "postgresql-private-connection"
    private_connection_resource_id = azurerm_postgresql_server.postgresql_server.id
    is_manual_connection           = false
    subresource_names              = ["postgresqlServer"]
  }
}

