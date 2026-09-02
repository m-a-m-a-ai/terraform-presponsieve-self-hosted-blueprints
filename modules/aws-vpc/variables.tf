variable "prefix" {
  description = "Name prefix applied to every resource this module creates."
  type        = string
}

variable "cidr_block" {
  description = "VPC CIDR. Must not overlap anything you peer with."
  type        = string
  default     = "10.20.0.0/16"
}

variable "availability_zone_count" {
  description = "Number of AZs to span. Three is the minimum for a highly available RDS and EKS."
  type        = number
  default     = 3

  validation {
    condition     = var.availability_zone_count >= 2
    error_message = "At least two availability zones are required."
  }
}

variable "single_nat_gateway" {
  description = <<-EOT
    Route all private egress through one NAT gateway instead of one per AZ.
    Cheaper, but a zone failure takes egress with it. False for production.
  EOT
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags applied to every resource."
  type        = map(string)
  default     = {}
}
