variable "prefix" {
  description = "Name prefix applied to every resource this module creates."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group to create the server in."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "database_subnet_id" {
  description = "Delegated subnet from the VNet module."
  type        = string
}

variable "private_dns_zone_id" {
  description = "Private DNS zone from the VNet module."
  type        = string
}

variable "key_vault_id" {
  description = "Key Vault to write the generated password into."
  type        = string
}

variable "sku_name" {
  description = <<-EOT
    Flexible Server SKU. GP_Standard_D2ds_v5 handles a few hundred profiles per
    hour. See guides/scaling.md before changing this.
  EOT
  type        = string
  default     = "GP_Standard_D2ds_v5"
}

variable "postgres_version" {
  description = "Postgres major version. Presponsieve supports 14 through 16."
  type        = string
  default     = "16"
}

variable "storage_mb" {
  description = "Storage allocation. Autogrow is enabled, so this is a floor."
  type        = number
  default     = 131072
}

variable "high_availability" {
  description = "Zone-redundant standby. True for production."
  type        = bool
  default     = true
}

variable "backup_retention_days" {
  description = "Days of automated backups to retain. Azure caps this at 35."
  type        = number
  default     = 35

  validation {
    condition     = var.backup_retention_days >= 7 && var.backup_retention_days <= 35
    error_message = "Azure supports between 7 and 35 days of backup retention."
  }
}

variable "tags" {
  description = "Tags applied to every resource."
  type        = map(string)
  default     = {}
}
