resource "random_password" "app" {
  length  = 32
  special = false # Avoids URL-encoding problems in connection strings.
}

resource "azurerm_postgresql_flexible_server" "this" {
  name                = "${var.prefix}-pg"
  resource_group_name = var.resource_group_name
  location            = var.location
  version             = var.postgres_version
  sku_name            = var.sku_name
  storage_mb          = var.storage_mb
  auto_grow_enabled   = true
  tags                = var.tags

  administrator_login    = "presponsieve"
  administrator_password = random_password.app.result

  # Private access. No public endpoint exists on this server at all.
  delegated_subnet_id           = var.database_subnet_id
  private_dns_zone_id           = var.private_dns_zone_id
  public_network_access_enabled = false

  backup_retention_days        = var.backup_retention_days
  geo_redundant_backup_enabled = false

  zone = "1"

  dynamic "high_availability" {
    for_each = var.high_availability ? [1] : []
    content {
      mode                      = "ZoneRedundant"
      standby_availability_zone = "2"
    }
  }

  maintenance_window {
    day_of_week  = 0
    start_hour   = 4
    start_minute = 0
  }

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [zone, high_availability[0].standby_availability_zone]
  }
}

resource "azurerm_postgresql_flexible_server_database" "presponsieve" {
  name      = "presponsieve"
  server_id = azurerm_postgresql_flexible_server.this.id
  charset   = "UTF8"
  collation = "en_US.utf8"

  lifecycle {
    prevent_destroy = true
  }
}

# Presponsieve stores trait embeddings, which requires pgvector. Azure gates
# extensions behind an allowlist parameter.
resource "azurerm_postgresql_flexible_server_configuration" "extensions" {
  name      = "azure.extensions"
  server_id = azurerm_postgresql_flexible_server.this.id
  value     = "VECTOR,PG_STAT_STATEMENTS,UUID-OSSP"
}

resource "azurerm_postgresql_flexible_server_configuration" "require_ssl" {
  name      = "require_secure_transport"
  server_id = azurerm_postgresql_flexible_server.this.id
  value     = "ON"
}

resource "azurerm_postgresql_flexible_server_configuration" "log_duration" {
  name      = "log_min_duration_statement"
  server_id = azurerm_postgresql_flexible_server.this.id
  value     = "1000"
}

# The password lives in Key Vault so the services module can sync it into the
# cluster. It never transits a chart value.
resource "azurerm_key_vault_secret" "db_password" {
  name         = "${var.prefix}-db-password"
  value        = random_password.app.result
  key_vault_id = var.key_vault_id
  content_type = "text/plain"
  tags         = var.tags
}
