output "static_ip_name" {
  description = <<-EOT
    Name of the reserved address. Pass to the Helm module in ingress
    annotations as kubernetes.io/ingress.global-static-ip-name.
  EOT
  value       = google_compute_global_address.this.name
}

output "address" {
  description = "The reserved address itself."
  value       = google_compute_global_address.this.address
}

output "ingress_annotations" {
  description = <<-EOT
    Annotations for the GCE ingress. The managed certificate name matches what
    the chart renders, which is <fullname>-cert.
  EOT
  value = {
    "kubernetes.io/ingress.global-static-ip-name" = google_compute_global_address.this.name
    "networking.gke.io/managed-certificates"      = "presponsieve-cert"
  }
}

output "dns_zone_name" {
  description = "Managed zone the record lives in."
  value       = local.zone_name
}

output "name_servers" {
  description = <<-EOT
    Delegate these at your registrar. The Google-managed certificate cannot be
    issued until delegation is live.
  EOT
  value       = var.create_dns_zone ? google_dns_managed_zone.this[0].name_servers : null
}
