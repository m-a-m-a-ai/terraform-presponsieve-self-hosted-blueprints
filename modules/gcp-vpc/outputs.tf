output "network_id" {
  description = "Fully qualified network ID."
  value       = google_compute_network.this.id
}

output "network_name" {
  description = "Network name."
  value       = google_compute_network.this.name
}

output "subnet_id" {
  description = "Node subnet ID."
  value       = google_compute_subnetwork.nodes.id
}

output "pods_range_name" {
  description = "Secondary range name for pods. Pass to the GKE module."
  value       = google_compute_subnetwork.nodes.secondary_ip_range[0].range_name
}

output "services_range_name" {
  description = "Secondary range name for services. Pass to the GKE module."
  value       = google_compute_subnetwork.nodes.secondary_ip_range[1].range_name
}

output "private_service_connection" {
  description = "Peering connection Cloud SQL depends on. Use to order the database module."
  value       = google_service_networking_connection.this.id
}
