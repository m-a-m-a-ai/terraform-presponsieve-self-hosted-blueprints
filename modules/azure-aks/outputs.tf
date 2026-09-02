output "cluster_name" {
  description = "Cluster name."
  value       = azurerm_kubernetes_cluster.this.name
}

output "cluster_id" {
  description = "Fully qualified cluster ID."
  value       = azurerm_kubernetes_cluster.this.id
}

output "host" {
  description = "API server endpoint."
  value       = azurerm_kubernetes_cluster.this.kube_config[0].host
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "Base64 CA certificate."
  value       = azurerm_kubernetes_cluster.this.kube_config[0].cluster_ca_certificate
  sensitive   = true
}

output "client_certificate" {
  description = "Client certificate for the admin kubeconfig."
  value       = azurerm_kubernetes_cluster.this.kube_config[0].client_certificate
  sensitive   = true
}

output "client_key" {
  description = "Client key for the admin kubeconfig."
  value       = azurerm_kubernetes_cluster.this.kube_config[0].client_key
  sensitive   = true
}

output "oidc_issuer_url" {
  description = "OIDC issuer for workload identity federation."
  value       = azurerm_kubernetes_cluster.this.oidc_issuer_url
}

output "kubelet_identity_object_id" {
  description = "Object ID of the kubelet identity. Grant it AcrPull where needed."
  value       = azurerm_kubernetes_cluster.this.kubelet_identity[0].object_id
}

output "node_resource_group" {
  description = "Resource group AKS manages node infrastructure in."
  value       = azurerm_kubernetes_cluster.this.node_resource_group
}

output "get_credentials_command" {
  description = "Copy-paste command to configure kubectl."
  value       = "az aks get-credentials --resource-group ${var.resource_group_name} --name ${azurerm_kubernetes_cluster.this.name}"
}
