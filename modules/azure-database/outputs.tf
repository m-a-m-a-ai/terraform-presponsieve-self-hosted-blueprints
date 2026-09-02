output "server_name" {
  description = "Flexible Server name."
  value       = azurerm_postgresql_flexible_server.this.name
}

output "host" {
  description = "Fully qualified domain name of the server."
  value       = azurerm_postgresql_flexible_server.this.fqdn
}

output "database_name" {
  description = "Database Presponsieve uses."
  value       = azurerm_postgresql_flexible_server_database.presponsieve.name
}

output "username" {
  description = "Administrator login."
  value       = azurerm_postgresql_flexible_server.this.administrator_login
}

output "password_secret_name" {
  description = "Key Vault secret holding the password. Pass to the services module."
  value       = azurerm_key_vault_secret.db_password.name
}
