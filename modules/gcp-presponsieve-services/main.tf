locals {
  gsa_email  = google_service_account.app.email
  ksa_member = "serviceAccount:${var.workload_identity_pool}[${var.namespace}/${var.service_account_name}]"

  # Cloud SQL takes the service account email with the suffix stripped.
  iam_db_user = replace(local.gsa_email, ".gserviceaccount.com", "")
}

# ---------------------------------------------------------------------------
# Workload identity. This one service account is the only credential in the
# deployment: it reaches Cloud SQL, GCS, Secret Manager, and signs V4 URLs.
# ---------------------------------------------------------------------------

resource "google_service_account" "app" {
  project      = var.project_id
  account_id   = "${var.prefix}-app"
  display_name = "Presponsieve application identity"
}

resource "google_service_account_iam_member" "workload_identity" {
  service_account_id = google_service_account.app.name
  role               = "roles/iam.workloadIdentityUser"
  member             = local.ksa_member
}

# Signing V4 URLs through IAM signBlob. Workload Identity credentials carry no
# private key, so the service account has to be able to sign as itself.
resource "google_service_account_iam_member" "token_creator" {
  service_account_id = google_service_account.app.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "serviceAccount:${local.gsa_email}"
}

resource "google_project_iam_member" "app" {
  for_each = toset(concat(
    ["roles/cloudsql.client", "roles/cloudsql.instanceUser"],
    var.enable_transcription ? ["roles/speech.client"] : [],
  ))

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${local.gsa_email}"
}

resource "google_secret_manager_secret_iam_member" "app" {
  project   = var.project_id
  secret_id = var.app_secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${local.gsa_email}"
}

# ---------------------------------------------------------------------------
# Report artifact storage
# ---------------------------------------------------------------------------

resource "google_storage_bucket" "artifacts" {
  project                     = var.project_id
  name                        = "${var.project_id}-${var.prefix}-artifacts"
  location                    = var.region
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  labels                      = var.labels

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      age = 90
    }
    action {
      type = "Delete"
    }
  }
}

resource "google_storage_bucket_iam_member" "app" {
  bucket = google_storage_bucket.artifacts.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${local.gsa_email}"
}

# ---------------------------------------------------------------------------
# The Kubernetes service account the chart's pods run as.
# ---------------------------------------------------------------------------

resource "kubernetes_service_account_v1" "app" {
  metadata {
    name      = var.service_account_name
    namespace = var.namespace

    annotations = {
      "iam.gke.io/gcp-service-account" = local.gsa_email
    }
  }
}
