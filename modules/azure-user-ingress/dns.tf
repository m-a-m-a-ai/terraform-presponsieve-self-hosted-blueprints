locals {
  # presponsieve.acme.com -> acme.com.
  parent_domain = join(".", slice(split(".", var.domain_name), 1, length(split(".", var.domain_name))))
  record_name   = split(".", var.domain_name)[0]
  zone_name     = var.create_dns_zone ? azurerm_dns_zone.this[0].name : var.dns_zone_name
}

resource "azurerm_dns_zone" "this" {
  count = var.create_dns_zone ? 1 : 0

  name                = local.parent_domain
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_dns_a_record" "app" {
  count = var.internal ? 0 : 1

  name                = local.record_name
  zone_name           = local.zone_name
  resource_group_name = var.resource_group_name
  ttl                 = 300
  target_resource_id  = azurerm_public_ip.this[0].id
  tags                = var.tags
}
