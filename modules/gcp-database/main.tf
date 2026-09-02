# No password is generated anywhere in this module. The workload connects
# through the Cloud SQL Auth Proxy using IAM database authentication, so the
# only credential involved is the pod's Workload Identity token.

resource "google_sql_database_instance" "this" {
  project             = var.project_id
  name                = "${var.prefix}-pg"
  region              = var.region
  database_version    = var.database_version
  deletion_protection = var.deletion_protection

  settings {
    tier              = var.tier
    availability_type = var.availability_type
    disk_size         = var.disk_size_gb
    disk_type         = "PD_SSD"
    disk_autoresize   = true
    user_labels       = var.labels

    ip_configuration {
      # No public IP. Reachable only from the peered VPC.
      ipv4_enabled                                  = false
      private_network                               = var.network_id
      enable_private_path_for_google_cloud_services = true
      ssl_mode                                      = "ENCRYPTED_ONLY"
    }

    backup_configuration {
      enabled                        = true
      start_time                     = "03:00"
      point_in_time_recovery_enabled = true
      transaction_log_retention_days = 7

      backup_retention_settings {
        retained_backups = var.backup_retention_count
        retention_unit   = "COUNT"
      }
    }

    maintenance_window {
      day          = 7
      hour         = 4
      update_track = "stable"
    }

    insights_config {
      query_insights_enabled  = true
      query_string_length     = 1024
      record_application_tags = true
    }

    # Required for the IAM database user below to be able to authenticate.
    database_flags {
      name  = "cloudsql.iam_authentication"
      value = "on"
    }

    database_flags {
      name  = "max_connections"
      value = "200"
    }
  }

  lifecycle {
    prevent_destroy = true
  }

  depends_on = [var.private_service_connection]
}

resource "google_sql_database" "presponsieve" {
  project  = var.project_id
  name     = "presponsieve"
  instance = google_sql_database_instance.this.name

  lifecycle {
    prevent_destroy = true
  }
}

# The IAM database user. Cloud SQL takes the service account email with the
# ".gserviceaccount.com" suffix removed; the Auth Proxy sidecar in the chart
# expects exactly the same string in cloudSqlProxy.iamUser.
resource "google_sql_user" "app" {
  project  = var.project_id
  instance = google_sql_database_instance.this.name
  name     = replace(var.app_service_account_email, ".gserviceaccount.com", "")
  type     = "CLOUD_IAM_SERVICE_ACCOUNT"
}
