output "service_account_email" {
  description = "GCP identity the workload assumes."
  value       = google_service_account.app.email
}

output "iam_db_user" {
  description = "Cloud SQL IAM user form of the service account email."
  value       = local.iam_db_user
}

output "kubernetes_service_account_name" {
  description = "Service account the pods run as."
  value       = kubernetes_service_account_v1.app.metadata[0].name
}

output "app_secret_name" {
  description = "Kubernetes secret holding the application secrets."
  value       = "presponsieve-secrets"
}

output "artifacts_bucket" {
  description = "Bucket holding generated report artifacts."
  value       = google_storage_bucket.artifacts.name
}

output "gcs_signer_service_account" {
  description = "Service account that signs V4 URLs. Pass to the Helm module."
  value       = google_service_account.app.email
}
