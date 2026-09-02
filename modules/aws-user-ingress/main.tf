locals {
  # presponsieve.acme.com -> acme.com.
  parent_domain = join(".", slice(split(".", var.domain_name), 1, length(split(".", var.domain_name))))
  zone_id       = var.create_dns_zone ? aws_route53_zone.this[0].zone_id : var.hosted_zone_id
}

resource "aws_route53_zone" "this" {
  count = var.create_dns_zone ? 1 : 0

  name    = local.parent_domain
  comment = "Hosted zone for the Presponsieve deployment."
  tags    = var.tags
}

# ---------------------------------------------------------------------------
# Certificate
# ---------------------------------------------------------------------------

resource "aws_acm_certificate" "this" {
  domain_name       = var.domain_name
  validation_method = "DNS"
  tags              = var.tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "validation" {
  for_each = {
    for o in aws_acm_certificate.this.domain_validation_options : o.domain_name => {
      name   = o.resource_record_name
      record = o.resource_record_value
      type   = o.resource_record_type
    }
  }

  zone_id         = local.zone_id
  name            = each.value.name
  type            = each.value.type
  records         = [each.value.record]
  ttl             = 60
  allow_overwrite = true
}

resource "aws_acm_certificate_validation" "this" {
  certificate_arn         = aws_acm_certificate.this.arn
  validation_record_fqdns = [for r in aws_route53_record.validation : r.fqdn]
}
