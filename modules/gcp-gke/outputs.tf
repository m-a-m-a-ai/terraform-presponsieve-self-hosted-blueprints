output "cluster_name" {
  description = "Cluster name."
  value       = google_container_cluster.this.name
}

output "cluster_id" {
  description = "Fully qualified cluster ID."
  value       = google_container_cluster.this.id
}

output "endpoint" {
  description = "Control plane endpoint."
  value       = google_container_cluster.this.endpoint
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "Base64 CA certificate for the control plane."
  value       = google_container_cluster.this.master_auth[0].cluster_ca_certificate
  sensitive   = true
}

output "workload_identity_pool" {
  description = "Workload identity pool. Pass to the services module."
  value       = "${var.project_id}.svc.id.goog"
}

output "node_service_account_email" {
  description = "Email of the node identity."
  value       = google_service_account.nodes.email
}

output "kms_key_ring_id" {
  description = "Key ring created for this deployment. Reused for application-level encryption."
  value       = google_kms_key_ring.this.id
}

output "get_credentials_command" {
  description = "Copy-paste command to configure kubectl."
  value       = "gcloud container clusters get-credentials ${google_container_cluster.this.name} --region ${var.region} --project ${var.project_id}"
}
