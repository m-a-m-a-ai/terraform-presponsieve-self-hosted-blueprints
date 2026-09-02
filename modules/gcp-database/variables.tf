variable "prefix" {
  description = "Name prefix applied to every resource this module creates."
  type        = string
}

variable "project_id" {
  description = "GCP project."
  type        = string
}

variable "region" {
  description = "Region for the instance."
  type        = string
}

variable "network_id" {
  description = "Network the instance gets a private IP on."
  type        = string
}

variable "private_service_connection" {
  description = "Peering connection from the VPC module. Creates an ordering dependency."
  type        = string
}

variable "app_service_account_email" {
  description = <<-EOT
    Service account the workload runs as. Added as an IAM database user, which
    is what makes password-less connection through the Auth Proxy work.
  EOT
  type        = string
}

variable "tier" {
  description = "Cloud SQL machine tier."
  type        = string
  default     = "db-custom-2-7680"
}

variable "disk_size_gb" {
  description = "Initial disk size. Autoresize is on, so this is a floor."
  type        = number
  default     = 100
}

variable "database_version" {
  description = "Postgres major version. Presponsieve supports 14 and later."
  type        = string
  default     = "POSTGRES_16"
}

variable "availability_type" {
  description = "REGIONAL gives a synchronous standby in a second zone."
  type        = string
  default     = "REGIONAL"
}

variable "backup_retention_count" {
  description = "Number of automated backups to retain."
  type        = number
  default     = 30
}

variable "deletion_protection" {
  description = "Blocks accidental destruction. Leave this on."
  type        = bool
  default     = true
}

variable "labels" {
  description = "Labels applied to the instance."
  type        = map(string)
  default     = {}
}
