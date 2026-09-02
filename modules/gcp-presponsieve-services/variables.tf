variable "prefix" {
  description = "Name prefix applied to every resource this module creates."
  type        = string
}

variable "project_id" {
  description = "GCP project."
  type        = string
}

variable "region" {
  description = "Region."
  type        = string
}

variable "namespace" {
  description = "Namespace the application runs in."
  type        = string
  default     = "presponsieve"
}

variable "service_account_name" {
  description = <<-EOT
    Kubernetes service account the workload runs as. The chart names it
    <fullname> when it creates one, which the Helm module pins to
    "presponsieve". Pass that here if you let the chart create it.
  EOT
  type        = string
  default     = "presponsieve"
}

variable "workload_identity_pool" {
  description = "Workload identity pool from the GKE module."
  type        = string
}

variable "cluster_name" {
  description = "GKE cluster name. External Secrets needs it for workload identity auth."
  type        = string
}

variable "app_secret_id" {
  description = <<-EOT
    Secret Manager secret holding the application secrets as a JSON object.
    Create it yourself so nothing sensitive touches Terraform:

      gcloud secrets create presponsieve-secrets --replication-policy=automatic
      jq -n --arg kek "$(openssl rand -base64 32)" \
            --arg sess "$(openssl rand -base64 32)" \
            --arg idx "$(openssl rand -base64 32)" \
            --arg tok "$(openssl rand -base64 32)" \
            --arg lic "$LICENSE_KEY" \
            '{APP_KEK:$kek, SESSION_SECRET:$sess, INDEX_PEPPER:$idx,
              AUTH_TOKEN_PEPPER:$tok, LICENSE_KEY:$lic}' \
        | gcloud secrets versions add presponsieve-secrets --data-file=-

    Add OPENAI_API_KEY to that object to enable narrative rendering.
  EOT
  type        = string
}

variable "secret_keys" {
  description = <<-EOT
    Keys to project out of the Secret Manager JSON object into the Kubernetes
    secret. Add OPENAI_API_KEY, MODEL_CONTENT_KEY, ACCESS_TOKENS, or
    GOOGLE_CLIENT_ID as needed.
  EOT
  type        = list(string)
  default     = ["APP_KEK", "SESSION_SECRET", "INDEX_PEPPER", "AUTH_TOKEN_PEPPER", "LICENSE_KEY"]
}

variable "secret_refresh_interval" {
  description = "How often External Secrets resyncs from Secret Manager."
  type        = string
  default     = "1h"
}

variable "enable_transcription" {
  description = <<-EOT
    Grant roles/speech.client so audio uploads can be transcribed with speaker
    diarization. The Speech-to-Text API must also be enabled on the project.
  EOT
  type        = bool
  default     = false
}

variable "labels" {
  description = "Labels applied to created resources."
  type        = map(string)
  default     = {}
}
