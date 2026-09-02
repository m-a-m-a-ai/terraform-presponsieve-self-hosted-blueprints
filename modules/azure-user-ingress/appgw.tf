resource "azurerm_public_ip" "this" {
  count = var.internal ? 0 : 1

  name                = "${var.prefix}-agw-pip"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1", "2", "3"]
  tags                = var.tags
}

resource "azurerm_user_assigned_identity" "gateway" {
  name                = "${var.prefix}-agw"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}

resource "azurerm_role_assignment" "gateway_certificates" {
  count = var.key_vault_id != null ? 1 : 0

  scope                = var.key_vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.gateway.principal_id
}

# The Application Gateway Ingress Controller rewrites most of this configuration
# once it starts reconciling the chart's Ingress resource. What is defined here
# is the minimum Azure requires to create the gateway at all.
resource "azurerm_application_gateway" "this" {
  name                = "${var.prefix}-agw"
  resource_group_name = var.resource_group_name
  location            = var.location
  zones               = ["1", "2", "3"]
  tags                = var.tags

  sku {
    name = "WAF_v2"
    tier = "WAF_v2"
  }

  autoscale_configuration {
    min_capacity = 2
    max_capacity = 10
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.gateway.id]
  }

  gateway_ip_configuration {
    name      = "gateway-ip"
    subnet_id = var.gateway_subnet_id
  }

  frontend_port {
    name = "https"
    port = 443
  }

  frontend_port {
    name = "http"
    port = 80
  }

  dynamic "frontend_ip_configuration" {
    for_each = var.internal ? [] : [1]
    content {
      name                 = "public"
      public_ip_address_id = azurerm_public_ip.this[0].id
    }
  }

  dynamic "frontend_ip_configuration" {
    for_each = var.internal ? [1] : []
    content {
      name                          = "private"
      subnet_id                     = var.gateway_subnet_id
      private_ip_address_allocation = "Dynamic"
    }
  }

  backend_address_pool {
    name = "placeholder"
  }

  backend_http_settings {
    name                  = "placeholder"
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 60
  }

  http_listener {
    name                           = "placeholder"
    frontend_ip_configuration_name = var.internal ? "private" : "public"
    frontend_port_name             = "http"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "placeholder"
    rule_type                  = "Basic"
    priority                   = 1000
    http_listener_name         = "placeholder"
    backend_address_pool_name  = "placeholder"
    backend_http_settings_name = "placeholder"
  }

  dynamic "ssl_certificate" {
    for_each = var.certificate_secret_name != null ? [1] : []
    content {
      name                = var.certificate_secret_name
      key_vault_secret_id = "${data.azurerm_key_vault.this[0].vault_uri}secrets/${var.certificate_secret_name}"
    }
  }

  ssl_policy {
    policy_type = "Predefined"
    policy_name = "AppGwSslPolicy20220101S"
  }

  waf_configuration {
    enabled          = true
    firewall_mode    = "Prevention"
    rule_set_type    = "OWASP"
    rule_set_version = "3.2"

    # Presponsieve accepts free text for analysis. The SQL injection ruleset
    # produces constant false positives against ordinary prose submitted to the
    # analysis endpoint.
    disabled_rule_group {
      rule_group_name = "REQUEST-942-APPLICATION-ATTACK-SQLI"
    }
  }

  lifecycle {
    # AGIC owns everything below once it starts reconciling.
    ignore_changes = [
      backend_address_pool,
      backend_http_settings,
      http_listener,
      probe,
      request_routing_rule,
      url_path_map,
      redirect_configuration,
      ssl_certificate,
      frontend_port,
      tags,
    ]
  }
}

data "azurerm_key_vault" "this" {
  count = var.key_vault_id != null ? 1 : 0

  name                = split("/", var.key_vault_id)[8]
  resource_group_name = split("/", var.key_vault_id)[4]
}

# Hands the gateway to AKS. From here the chart's Ingress resource drives it.
resource "azurerm_kubernetes_cluster_extension" "agic" {
  name           = "agic"
  cluster_id     = var.cluster_id
  extension_type = "Microsoft.ApplicationGatewayIngressController"

  configuration_settings = {
    "appgw.applicationGatewayId" = azurerm_application_gateway.this.id
    "appgw.shared"               = "false"
  }
}
