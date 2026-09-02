variable "prefix" {
  description = "Name prefix applied to every resource this module creates."
  type        = string
}

variable "project_id" {
  description = "GCP project to create the network in."
  type        = string
}

variable "region" {
  description = "Region for the subnet and Cloud NAT gateway."
  type        = string
}

variable "subnet_cidr" {
  description = "Primary CIDR for the node subnet."
  type        = string
  default     = "10.20.0.0/20"
}

variable "pods_cidr" {
  description = "Secondary range for GKE pods. Size this for peak node count times 110."
  type        = string
  default     = "10.24.0.0/14"
}

variable "services_cidr" {
  description = "Secondary range for GKE services."
  type        = string
  default     = "10.28.0.0/20"
}

variable "labels" {
  description = "Labels applied to labelable resources."
  type        = map(string)
  default     = {}
}
