variable "prefix" {
  description = "Name prefix applied to every resource this module creates."
  type        = string
}

variable "project_id" {
  description = "GCP project to create the cluster in."
  type        = string
}

variable "region" {
  description = "Region for the regional cluster."
  type        = string
}

variable "network_id" {
  description = "Network to attach the cluster to."
  type        = string
}

variable "subnet_id" {
  description = "Subnet for cluster nodes."
  type        = string
}

variable "pods_range_name" {
  description = "Secondary range name for pods."
  type        = string
}

variable "services_range_name" {
  description = "Secondary range name for services."
  type        = string
}

variable "master_authorized_networks" {
  description = <<-EOT
    CIDRs permitted to reach the control plane. Defaults to nothing, which means
    only the cluster's own nodes and Google-internal callers. Add your VPN or
    bastion range before you try to run kubectl.
  EOT
  type = list(object({
    cidr_block   = string
    display_name = string
  }))
  default = []
}

variable "node_machine_type" {
  description = <<-EOT
    Machine type for the general node pool. Worker pods request 4Gi, so anything
    below n2-standard-4 will schedule badly.
  EOT
  type        = string
  default     = "n2-standard-4"
}

variable "node_min_count" {
  description = "Minimum nodes per zone in the autoscaling pool."
  type        = number
  default     = 1
}

variable "node_max_count" {
  description = "Maximum nodes per zone in the autoscaling pool."
  type        = number
  default     = 5
}

variable "release_channel" {
  description = "GKE release channel. STABLE is correct for production."
  type        = string
  default     = "STABLE"
}

variable "labels" {
  description = "Labels applied to the cluster and node pool."
  type        = map(string)
  default     = {}
}
