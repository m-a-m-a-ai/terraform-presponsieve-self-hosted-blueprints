output "ingress_class_name" {
  description = "Ingress class the chart should use. Pass to presponsieve-helm."
  value       = "azure-application-gateway"
}

output "ingress_annotations" {
  description = "Annotations AGIC needs. Pass into presponsieve-helm's ingress.annotations."
  value = merge(
    {
      "appgw.ingress.kubernetes.io/health-probe-path" = "/healthz"
      "appgw.ingress.kubernetes.io/ssl-redirect"      = "true"
      "appgw.ingress.kubernetes.io/backend-protocol"  = "http"
      "appgw.ingress.kubernetes.io/request-timeout"   = "120"
    },
    var.certificate_secret_name != null ? {
      "appgw.ingress.kubernetes.io/appgw-ssl-certificate" = var.certificate_secret_name
    } : {},
  )
}

output "gateway_id" {
  description = "Application Gateway resource ID."
  value       = azurerm_application_gateway.this.id
}

output "public_ip" {
  description = "Public address the domain resolves to. Null for internal deployments."
  value       = var.internal ? null : azurerm_public_ip.this[0].ip_address
}

output "dns_zone_name" {
  description = "DNS zone the record lives in."
  value       = local.zone_name
}

output "name_servers" {
  description = "Name servers to delegate to at your registrar. Null when using an existing zone."
  value       = var.create_dns_zone ? azurerm_dns_zone.this[0].name_servers : null
}
