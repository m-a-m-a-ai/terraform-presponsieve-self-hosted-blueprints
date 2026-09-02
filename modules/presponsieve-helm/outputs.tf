output "release_name" {
  description = "Helm release name."
  value       = helm_release.presponsieve.name
}

output "namespace" {
  description = "Namespace the release lives in."
  value       = helm_release.presponsieve.namespace
}

output "chart_version" {
  description = "Chart version installed."
  value       = helm_release.presponsieve.version
}

output "service_name" {
  description = "Service name. This is what you port-forward to."
  value       = var.fullname_override
}

output "url" {
  description = "Address users reach the application on."
  value       = "https://${var.domain_name}"
}

output "port_forward_command" {
  description = "Reach the app without going through the ingress."
  value       = "kubectl port-forward -n ${var.namespace} svc/${var.fullname_override} 8080:80"
}

output "values" {
  description = "Fully merged chart values. Useful when a release fails to become ready."
  value       = local.values
  sensitive   = true
}
