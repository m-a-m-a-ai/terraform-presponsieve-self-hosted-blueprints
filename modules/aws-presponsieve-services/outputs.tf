output "app_role_arn" {
  description = "IAM role the workload assumes through IRSA."
  value       = aws_iam_role.app.arn
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
  value       = aws_s3_bucket.artifacts.bucket
}
