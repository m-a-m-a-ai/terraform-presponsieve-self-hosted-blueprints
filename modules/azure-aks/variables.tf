variable "prefix" {
  description = "Name prefix applied to every resource this module creates."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group to create the cluster in."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "nodes_subnet_id" {
  description = "Subnet for cluster nodes."
  type        = string
}

variable "kubernetes_version" {
  description = "AKS version."
  type        = string
  default     = "1.31"
}

variable "authorized_ip_ranges" {
  description = <<-EOT
    CIDRs permitted to reach the API server. Defaults to nothing. Add your VPN
    egress range before you try to run kubectl.
  EOT
  type        = list(string)
  default     = []
}

variable "node_vm_size" {
  description = <<-EOT
    VM size for the general node pool. Worker pods request 4Gi, so anything
    smaller than Standard_D4s_v5 schedules badly.
  EOT
  type        = string
  default     = "Standard_D4s_v5"
}

variable "node_min_count" {
  description = "Minimum nodes in the autoscaling pool."
  type        = number
  default     = 3
}

variable "node_max_count" {
  description = "Maximum nodes in the autoscaling pool."
  type        = number
  default     = 12
}

variable "availability_zones" {
  description = "Zones to spread nodes across."
  type        = list(string)
  default     = ["1", "2", "3"]
}

variable "log_analytics_workspace_id" {
  description = "Workspace for container insights. Null disables monitoring."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags applied to every resource."
  type        = map(string)
  default     = {}
}

variable "tenant_id" {
  description = "Entra ID tenant backing cluster RBAC."
  type        = string
}

variable "admin_group_object_ids" {
  description = "Entra ID group object IDs granted cluster admin. Local accounts are disabled, so this is the only path to admin on a fresh cluster."
  type        = list(string)
  default     = []
}
