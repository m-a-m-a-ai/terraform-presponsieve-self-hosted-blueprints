output "url" {
  description = "Where to reach the application."
  value       = module.presponsieve.url
}

output "address" {
  description = "Address the domain resolves to."
  value       = module.ingress.address
}

output "name_servers" {
  description = "Delegate these at your registrar. Certificate issuance blocks until you do."
  value       = module.ingress.name_servers
}

output "kubectl" {
  description = "Configure kubectl against the cluster."
  value       = module.gke.get_credentials_command
}

output "port_forward" {
  description = "Reach the app without going through the load balancer."
  value       = module.presponsieve.port_forward_command
}

output "cloud_sql_connection_name" {
  description = "Instance the Auth Proxy sidecar connects to."
  value       = module.database.connection_name
}
