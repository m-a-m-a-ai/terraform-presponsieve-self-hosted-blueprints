variable "prefix" {
  description = "Name prefix applied to every resource this module creates."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group."
  type        = string
}

variable "location" {
  description = "Azure region."
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

variable "oidc_issuer_url" {
  description = "AKS OIDC issuer URL, for workload identity federation."
  type        = string
}

variable "tenant_id" {
  description = "Entra ID tenant."
  type        = string
}

variable "secret_keys" {
  description = "Key Vault secret names projected into the Kubernetes secret."
  type        = list(string)
  default     = ["APP-KEK", "SESSION-SECRET", "INDEX-PEPPER", "AUTH-TOKEN-PEPPER", "LICENSE-KEY", "DATABASE-URL"]
}

variable "secret_refresh_interval" {
  description = "How often External Secrets resyncs from Key Vault."
  type        = string
  default     = "1h"
}

variable "tags" {
  description = "Tags applied to every resource."
  type        = map(string)
  default     = {}
}
