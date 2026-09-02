variable "prefix" {
  description = "Name prefix applied to every resource this module creates."
  type        = string
}

variable "namespace" {
  description = "Namespace the application runs in."
  type        = string
  default     = "presponsieve"
}

variable "service_account_name" {
  description = "Kubernetes service account the workload runs as."
  type        = string
  default     = "presponsieve"
}

variable "oidc_provider_arn" {
  description = "IAM OIDC provider ARN from the EKS module."
  type        = string
}

variable "oidc_provider_url" {
  description = "OIDC issuer URL without the scheme."
  type        = string
}

variable "app_secret_name" {
  description = <<-EOT
    Secrets Manager secret holding the application secrets as a JSON object.
    Create it yourself so nothing sensitive touches Terraform:

      aws secretsmanager create-secret --name presponsieve/app \
        --secret-string "$(jq -n \
          --arg kek  "$(openssl rand -base64 32)" \
          --arg sess "$(openssl rand -base64 32)" \
          --arg idx  "$(openssl rand -base64 32)" \
          --arg tok  "$(openssl rand -base64 32)" \
          --arg lic  "$LICENSE_KEY" \
          '{APP_KEK:$kek, SESSION_SECRET:$sess, INDEX_PEPPER:$idx,
            AUTH_TOKEN_PEPPER:$tok, LICENSE_KEY:$lic}')"
  EOT
  type        = string
}

variable "secret_keys" {
  description = "Keys to project from the JSON object into the Kubernetes secret."
  type        = list(string)
  default     = ["APP_KEK", "SESSION_SECRET", "INDEX_PEPPER", "AUTH_TOKEN_PEPPER", "LICENSE_KEY", "DATABASE_URL"]
}

variable "secret_refresh_interval" {
  description = "How often External Secrets resyncs from Secrets Manager."
  type        = string
  default     = "1h"
}

variable "tags" {
  description = "Tags applied to every resource."
  type        = map(string)
  default     = {}
}
