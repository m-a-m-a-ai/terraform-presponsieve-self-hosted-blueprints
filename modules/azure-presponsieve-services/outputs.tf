output "key_vault_id" {
  description = "Key Vault holding the application secrets."
  value       = azurerm_key_vault.this.id
}

output "key_vault_name" {
  description = "Key Vault name, for the az CLI commands in the README."
  value       = azurerm_key_vault.this.name
}

output "kubernetes_service_account_name" {
  description = "Service account the pods run as."
  value       = kubernetes_service_account_v1.app.metadata[0].name
}

output "app_secret_name" {
  description = "Kubernetes secret holding the application secrets."
  value       = "presponsieve-secrets"
}

output "artifacts_storage_account" {
  description = "Storage account holding report artifacts."
  value       = azurerm_storage_account.artifacts.name
}
