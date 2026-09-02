variable "prefix" {
  description = "Name prefix applied to every resource this module creates."
  type        = string
}

variable "vpc_id" {
  description = "VPC the load balancer lives in."
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name."
  type        = string
}

variable "oidc_provider_arn" {
  description = "IAM OIDC provider ARN from the EKS module."
  type        = string
}

variable "oidc_provider_url" {
  description = "OIDC issuer URL without the scheme."
  type        = string
}

variable "domain_name" {
  description = "Fully qualified domain users reach Presponsieve on."
  type        = string
}

variable "create_dns_zone" {
  description = "Whether to create a Route 53 hosted zone for the parent domain."
  type        = bool
  default     = true
}

variable "hosted_zone_id" {
  description = "Existing hosted zone ID to write into when create_dns_zone is false."
  type        = string
  default     = null
}

variable "internal" {
  description = <<-EOT
    Use an internal ALB, reachable only from the VPC and anything peered to it.
    Correct for most enterprise deployments, where users arrive over VPN or
    Direct Connect.
  EOT
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags applied to every resource."
  type        = map(string)
  default     = {}
}
