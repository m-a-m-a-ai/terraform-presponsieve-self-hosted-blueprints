output "url" {
  description = "Where to reach Presponsieve."
  value       = module.presponsieve.url
}

output "port_forward" {
  description = "Reach the app without going through the ALB."
  value       = module.presponsieve.port_forward_command
}

output "name_servers" {
  description = "Delegate these at your registrar. Certificate validation blocks until you do."
  value       = module.ingress.name_servers
}

output "dns_instructions" {
  description = "How to point the domain at the ALB once it exists."
  value       = module.ingress.dns_instructions
}

output "kubectl" {
  description = "Configure kubectl against the cluster."
  value       = module.eks.update_kubeconfig_command
}

output "database_host" {
  description = "RDS endpoint."
  value       = module.database.host
}
