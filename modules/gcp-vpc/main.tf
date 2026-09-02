resource "google_compute_network" "this" {
  project                 = var.project_id
  name                    = "${var.prefix}-vpc"
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
  description             = "Network for the Presponsieve deployment."
}

resource "google_compute_subnetwork" "nodes" {
  project       = var.project_id
  name          = "${var.prefix}-nodes"
  network       = google_compute_network.this.id
  region        = var.region
  ip_cidr_range = var.subnet_cidr

  # Required for Private Service Connect to Cloud SQL and for private GKE nodes.
  private_ip_google_access = true

  secondary_ip_range {
    range_name    = "${var.prefix}-pods"
    ip_cidr_range = var.pods_cidr
  }

  secondary_ip_range {
    range_name    = "${var.prefix}-services"
    ip_cidr_range = var.services_cidr
  }

  log_config {
    aggregation_interval = "INTERVAL_10_MIN"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

# Nodes are private. NAT exists so they can reach the container registry and
# your OIDC provider. In an air-gapped deployment you can remove this entirely
# once images are mirrored internally.
resource "google_compute_router" "this" {
  project = var.project_id
  name    = "${var.prefix}-router"
  region  = var.region
  network = google_compute_network.this.id
}

# Compute networks and routers do not take labels. Applied to the reserved
# peering range, which does, so the variable is not dead.


resource "google_compute_router_nat" "this" {
  project                            = var.project_id
  name                               = "${var.prefix}-nat"
  router                             = google_compute_router.this.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

# Reserved block that Cloud SQL peers into.
resource "google_compute_global_address" "private_service_access" {
  project       = var.project_id
  name          = "${var.prefix}-psa"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 20
  network       = google_compute_network.this.id
  labels        = var.labels
}

resource "google_service_networking_connection" "this" {
  network                 = google_compute_network.this.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_service_access.name]
}
