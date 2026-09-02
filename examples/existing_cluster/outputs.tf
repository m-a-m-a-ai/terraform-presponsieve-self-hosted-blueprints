output "url" {
  description = "Where to reach the application."
  value       = module.presponsieve.url
}

output "namespace" {
  description = "Namespace the release lives in."
  value       = module.presponsieve.namespace
}

output "port_forward" {
  description = "Reach the app without going through the ingress."
  value       = module.presponsieve.port_forward_command
}
