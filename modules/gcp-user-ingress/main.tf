locals {
  # app.acme.com -> acme.com.
  parent_domain = join(".", slice(split(".", var.domain_name), 1, length(split(".", var.domain_name))))
  zone_name     = var.create_dns_zone ? google_dns_managed_zone.this[0].name : var.dns_zone_name
}

# The GCE ingress needs a reserved global address that outlives the Ingress
# resource. The chart references it by name through
# kubernetes.io/ingress.global-static-ip-name.
resource "google_compute_global_address" "this" {
  project      = var.project_id
  name         = "${var.prefix}-ip"
  address_type = "EXTERNAL"
}

resource "google_dns_managed_zone" "this" {
  count = var.create_dns_zone ? 1 : 0

  project     = var.project_id
  name        = "${var.prefix}-zone"
  dns_name    = "${local.parent_domain}."
  description = "Managed zone for the Presponsieve deployment."
  labels      = var.labels
}

resource "google_dns_record_set" "app" {
  project      = var.project_id
  managed_zone = local.zone_name
  name         = "${var.domain_name}."
  type         = "A"
  ttl          = 300
  rrdatas      = [google_compute_global_address.this.address]
}
