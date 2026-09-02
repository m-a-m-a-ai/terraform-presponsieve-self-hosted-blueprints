output "url" {
  description = "Where to reach Presponsieve."
  value       = module.presponsieve.url
}

output "public_ip" {
  description = "Address the domain must resolve to."
  value       = module.ingress.public_ip
}

output "name_servers" {
  description = "Delegate these at your registrar."
  value       = module.ingress.name_servers
}

output "kubectl" {
  description = "Configure kubectl against the cluster."
  value       = module.aks.get_credentials_command
}

output "key_vault_name" {
  description = "Key Vault holding the application secrets."
  value       = module.services.key_vault_name
}
