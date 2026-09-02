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

variable "labels" {
  description = "Labels applied to created resources."
  type        = map(string)
  default     = {}
}
