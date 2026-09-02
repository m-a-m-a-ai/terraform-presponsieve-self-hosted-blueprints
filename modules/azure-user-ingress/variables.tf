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

variable "cluster_id" {
  description = "AKS cluster ID. The AGIC addon is enabled on it."
  type        = string
}

variable "gateway_subnet_id" {
  description = "Dedicated Application Gateway subnet from the VNet module."
  type        = string
}

variable "domain_name" {
  description = "Fully qualified domain users reach Presponsieve on."
  type        = string
}

variable "create_dns_zone" {
  description = "Whether to create a public DNS zone for the parent domain."
  type        = bool
  default     = true
}

variable "dns_zone_name" {
  description = "Existing DNS zone name to write into when create_dns_zone is false."
  type        = string
  default     = null
}

variable "key_vault_id" {
  description = "Key Vault holding the TLS certificate, when bringing your own."
  type        = string
  default     = null
}

variable "certificate_secret_name" {
  description = <<-EOT
    Key Vault certificate name to serve. Azure does not offer free managed
    certificates for Application Gateway, so you must supply one. Import it into
    Key Vault first.
  EOT
  type        = string
  default     = null
}

variable "internal" {
  description = <<-EOT
    Private frontend only, reachable from the VNet and anything peered to it.
    Correct for most enterprise deployments.
  EOT
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags applied to every resource."
  type        = map(string)
  default     = {}
}
