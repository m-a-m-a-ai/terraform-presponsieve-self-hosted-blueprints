variable "prefix" {
  description = "Name prefix applied to every resource this module creates."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group to create the network in."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "address_space" {
  description = "VNet address space."
  type        = list(string)
  default     = ["10.20.0.0/16"]
}

variable "nodes_subnet_cidr" {
  description = "Subnet for AKS nodes and pods under Azure CNI overlay."
  type        = string
  default     = "10.20.0.0/20"
}

variable "database_subnet_cidr" {
  description = "Delegated subnet for the Postgres Flexible Server."
  type        = string
  default     = "10.20.16.0/24"
}

variable "gateway_subnet_cidr" {
  description = "Subnet for the Application Gateway. Must not hold anything else."
  type        = string
  default     = "10.20.17.0/24"
}

variable "tags" {
  description = "Tags applied to every resource."
  type        = map(string)
  default     = {}
}
