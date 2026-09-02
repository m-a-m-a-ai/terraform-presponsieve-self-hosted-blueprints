output "ingress_class_name" {
  description = "Ingress class the chart should use. Pass to presponsieve-helm."
  value       = "alb"
}

output "ingress_annotations" {
  description = <<-EOT
    Annotations the ALB controller needs. Pass straight into
    presponsieve-helm's ingress.annotations.
  EOT
  value = {
    "alb.ingress.kubernetes.io/scheme"             = var.internal ? "internal" : "internet-facing"
    "alb.ingress.kubernetes.io/target-type"        = "ip"
    "alb.ingress.kubernetes.io/certificate-arn"    = aws_acm_certificate.this.arn
    "alb.ingress.kubernetes.io/listen-ports"       = jsonencode([{ HTTP = 80 }, { HTTPS = 443 }])
    "alb.ingress.kubernetes.io/ssl-redirect"       = "443"
    "alb.ingress.kubernetes.io/ssl-policy"         = "ELBSecurityPolicy-TLS13-1-2-2021-06"
    "alb.ingress.kubernetes.io/healthcheck-path"   = "/healthz"
    "alb.ingress.kubernetes.io/load-balancer-name" = "${var.prefix}-alb"
    "alb.ingress.kubernetes.io/backend-protocol"   = "HTTP"
    "external-dns.alpha.kubernetes.io/hostname"    = var.domain_name
  }
}

output "certificate_arn" {
  description = "ACM certificate serving the domain."
  value       = aws_acm_certificate.this.arn
}

output "hosted_zone_id" {
  description = "Hosted zone the record lives in."
  value       = local.zone_id
}

output "name_servers" {
  description = <<-EOT
    Name servers to delegate to at your registrar. Null when using an existing
    zone. Certificate validation blocks until delegation is live.
  EOT
  value       = var.create_dns_zone ? aws_route53_zone.this[0].name_servers : null
}

output "dns_instructions" {
  description = "What to do once the ALB exists."
  value       = "Create an ALIAS A record for ${var.domain_name} in zone ${local.zone_id} pointing at the ALB provisioned by the Ingress. Retrieve it with: kubectl get ingress -n presponsieve"
}
