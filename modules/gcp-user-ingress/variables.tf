variable "prefix" {
  description = "Name prefix applied to every resource this module creates."
  type        = string
}

variable "project_id" {
  description = "GCP project."
  type        = string
}

variable "domain_name" {
  description = "Host users reach the application on."
  type        = string
}

variable "create_dns_zone" {
  description = "Whether to create a managed zone for the parent domain."
  type        = bool
  default     = true
}

variable "dns_zone_name" {
  description = "Existing managed zone to write into when create_dns_zone is false."
  type        = string
  default     = null
}

variable "iap_oauth_client_id" {
  description = <<-EOT
    OAuth client ID for Identity-Aware Proxy. Create the client by hand in the
    console; Google does not expose brand or client creation for internal
    OAuth consent screens through Terraform in every configuration.
  EOT
  type        = string
  default     = null
}

variable "iap_oauth_client_secret" {
  description = "OAuth client secret for IAP. Written to a Kubernetes secret by the services module."
  type        = string
  default     = null
  sensitive   = true
}

variable "labels" {
  description = "Labels applied to created resources."
  type        = map(string)
  default     = {}
}
