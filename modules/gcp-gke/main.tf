resource "google_service_account" "nodes" {
  project      = var.project_id
  account_id   = "${var.prefix}-gke-nodes"
  display_name = "Presponsieve GKE node identity"
}

# Least privilege for nodes. Workload identity handles application permissions,
# so the node identity only needs to write telemetry and pull images.
resource "google_project_iam_member" "nodes" {
  for_each = toset([
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer",
    "roles/artifactregistry.reader",
  ])

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.nodes.email}"
}

resource "google_container_cluster" "this" {
  project  = var.project_id
  name     = "${var.prefix}-gke"
  location = var.region

  network    = var.network_id
  subnetwork = var.subnet_id

  # We manage node pools separately so they can be replaced without touching
  # the control plane.
  remove_default_node_pool = true
  initial_node_count       = 1

  release_channel {
    channel = var.release_channel
  }

  ip_allocation_policy {
    cluster_secondary_range_name  = var.pods_range_name
    services_secondary_range_name = var.services_range_name
  }

  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = "172.16.0.0/28"
  }

  # Always rendered. An absent block leaves the public endpoint open to the
  # entire internet; an empty one restricts it to Google-internal callers.
  # The default is therefore closed, and you open it by naming CIDRs.
  master_authorized_networks_config {
    dynamic "cidr_blocks" {
      for_each = var.master_authorized_networks
      content {
        cidr_block   = cidr_blocks.value.cidr_block
        display_name = cidr_blocks.value.display_name
      }
    }
  }

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  # Envelope encryption for secrets at rest in etcd.
  database_encryption {
    state    = "ENCRYPTED"
    key_name = google_kms_crypto_key.etcd.id
  }

  network_policy {
    enabled  = true
    provider = "CALICO"
  }

  addons_config {
    horizontal_pod_autoscaling { disabled = false }
    http_load_balancing { disabled = false }
    gcs_fuse_csi_driver_config { enabled = true }
  }

  gateway_api_config {
    channel = "CHANNEL_STANDARD"
  }

  logging_config {
    enable_components = ["SYSTEM_COMPONENTS", "WORKLOADS"]
  }

  monitoring_config {
    enable_components = ["SYSTEM_COMPONENTS"]
    managed_prometheus { enabled = true }
  }

  deletion_protection = true

  resource_labels = var.labels

  depends_on = [google_kms_crypto_key_iam_member.etcd]
}

resource "google_container_node_pool" "general" {
  project  = var.project_id
  name     = "${var.prefix}-general"
  cluster  = google_container_cluster.this.id
  location = var.region

  autoscaling {
    min_node_count = var.node_min_count
    max_node_count = var.node_max_count
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  upgrade_settings {
    strategy        = "SURGE"
    max_surge       = 1
    max_unavailable = 0
  }

  node_config {
    machine_type = var.node_machine_type
    disk_size_gb = 100
    disk_type    = "pd-balanced"

    service_account = google_service_account.nodes.email
    oauth_scopes    = ["https://www.googleapis.com/auth/cloud-platform"]

    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }

    labels = var.labels

    metadata = {
      disable-legacy-endpoints = "true"
    }
  }

  lifecycle {
    ignore_changes = [node_config[0].labels]
  }
}

# ---------------------------------------------------------------------------
# etcd encryption key
# ---------------------------------------------------------------------------

resource "google_kms_key_ring" "this" {
  project  = var.project_id
  name     = "${var.prefix}-keyring"
  location = var.region
}

resource "google_kms_crypto_key" "etcd" {
  name     = "${var.prefix}-etcd"
  key_ring = google_kms_key_ring.this.id
  purpose  = "ENCRYPT_DECRYPT"

  rotation_period = "7776000s" # 90 days

  lifecycle {
    prevent_destroy = true
  }
}

data "google_project" "this" {
  project_id = var.project_id
}

resource "google_kms_crypto_key_iam_member" "etcd" {
  crypto_key_id = google_kms_crypto_key.etcd.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:service-${data.google_project.this.number}@container-engine-robot.iam.gserviceaccount.com"
}
