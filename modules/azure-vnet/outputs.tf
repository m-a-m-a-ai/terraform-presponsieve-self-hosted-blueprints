output "vnet_id" {
  description = "VNet ID."
  value       = azurerm_virtual_network.this.id
}

output "vnet_name" {
  description = "VNet name."
  value       = azurerm_virtual_network.this.name
}

output "nodes_subnet_id" {
  description = "Subnet for AKS nodes."
  value       = azurerm_subnet.nodes.id
}

output "database_subnet_id" {
  description = "Delegated subnet for the Postgres Flexible Server."
  value       = azurerm_subnet.database.id
}

output "gateway_subnet_id" {
  description = "Subnet for the Application Gateway."
  value       = azurerm_subnet.gateway.id
}

output "postgres_private_dns_zone_id" {
  description = "Private DNS zone the Flexible Server registers in."
  value       = azurerm_private_dns_zone.postgres.id
}
