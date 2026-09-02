variable "prefix" {
  description = "Name prefix applied to every resource this module creates."
  type        = string
}

variable "vpc_id" {
  description = "VPC to create the cluster in."
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnets for nodes and the control plane ENIs."
  type        = list(string)
}

variable "kubernetes_version" {
  description = "EKS control plane version."
  type        = string
  default     = "1.31"
}

variable "public_access_cidrs" {
  description = <<-EOT
    CIDRs permitted to reach the public API endpoint. Defaults to nothing.
    Add your VPN egress range before you try to run kubectl.
  EOT
  type        = list(string)
  default     = []
}

variable "node_instance_types" {
  description = <<-EOT
    Instance types for the managed node group. Worker pods request 4Gi, so
    anything smaller than m6i.xlarge schedules badly.
  EOT
  type        = list(string)
  default     = ["m6i.xlarge"]
}

variable "node_min_size" {
  description = "Minimum nodes in the managed group."
  type        = number
  default     = 3
}

variable "node_max_size" {
  description = "Maximum nodes in the managed group."
  type        = number
  default     = 12
}

variable "node_desired_size" {
  description = "Starting node count."
  type        = number
  default     = 3
}

variable "tags" {
  description = "Tags applied to every resource."
  type        = map(string)
  default     = {}
}
