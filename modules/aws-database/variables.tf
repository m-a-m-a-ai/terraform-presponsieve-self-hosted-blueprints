variable "prefix" {
  description = "Name prefix applied to every resource this module creates."
  type        = string
}

variable "vpc_id" {
  description = "VPC to create the instance in."
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnets for the DB subnet group. Needs at least two AZs."
  type        = list(string)
}

variable "allowed_security_group_ids" {
  description = "Security groups permitted to reach Postgres. Pass the EKS node security group."
  type        = list(string)
}

variable "instance_class" {
  description = <<-EOT
    RDS instance class. db.m6g.large handles a few hundred profiles per hour.
    See guides/scaling.md before changing this.
  EOT
  type        = string
  default     = "db.m6g.large"
}

variable "engine_version" {
  description = "Postgres version. Presponsieve supports 14 through 16."
  type        = string
  default     = "16.4"
}

variable "allocated_storage_gb" {
  description = "Initial storage. Autoscaling is enabled, so this is a floor."
  type        = number
  default     = 100
}

variable "max_allocated_storage_gb" {
  description = "Ceiling for storage autoscaling."
  type        = number
  default     = 1000
}

variable "multi_az" {
  description = "Synchronous standby in a second AZ. True for production."
  type        = bool
  default     = true
}

variable "backup_retention_days" {
  description = "Days of automated backups to retain."
  type        = number
  default     = 30
}

variable "deletion_protection" {
  description = "Blocks accidental destruction. Leave this on."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags applied to every resource."
  type        = map(string)
  default     = {}
}
