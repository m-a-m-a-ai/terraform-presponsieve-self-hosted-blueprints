# ---------------------------------------------------------------------------
# Edit this block. Nothing else in the file needs to change for a standard
# deployment.
# ---------------------------------------------------------------------------

locals {
  prefix          = "presponsieve"
  subscription_id = "00000000-0000-0000-0000-000000000000"
  tenant_id       = "00000000-0000-0000-0000-000000000000"
  location        = "eastus2"
  domain_name     = "app.acme.com"

  # Certificate for the Application Gateway. Azure has no free managed option,
  # so import a PFX into Key Vault first:
  #   az keyvault certificate import --vault-name <vault> \
  #     --name presponsieve-tls --file cert.pfx
  certificate_secret_name = "presponsieve-tls"

  # Your identity provider. Azure has no IAP equivalent for this app, so SSO
  # is OIDC, typically against Entra ID.
  oidc_issuer_url = "https://login.microsoftonline.com/TENANT/v2.0"
  oidc_client_id  = "11111111-2222-3333-4444-555555555555"

  # Pin these. See guides/upgrades.md.
  chart_version = "0.1.0"
  image_tag     = "0.1.0"

  # Add your VPN egress range. Empty means you cannot reach the API server.
  admin_cidrs = [
    # "203.0.113.0/24",
  ]

  tags = {
    application = "presponsieve"
    managedBy   = "terraform"
  }
}

resource "azurerm_resource_group" "this" {
  name     = "${local.prefix}-rg"
  location = local.location
  tags     = local.tags
}

# ---------------------------------------------------------------------------
# Network
# ---------------------------------------------------------------------------

module "vnet" {
  source = "../../modules/azure-vnet"

  prefix              = local.prefix
  resource_group_name = azurerm_resource_group.this.name
  location            = local.location
  tags                = local.tags
}

# ---------------------------------------------------------------------------
# Cluster
# ---------------------------------------------------------------------------

module "aks" {
  source = "../../modules/azure-aks"

  prefix              = local.prefix
  resource_group_name = azurerm_resource_group.this.name
  location            = local.location
  tenant_id           = local.tenant_id
  nodes_subnet_id     = module.vnet.nodes_subnet_id

  authorized_ip_ranges = local.admin_cidrs
  tags                 = local.tags
}

# ---------------------------------------------------------------------------
# Identity, secrets, storage. Runs before the database because it owns the
# Key Vault the database password is written into.
# ---------------------------------------------------------------------------

module "services" {
  source = "../../modules/azure-presponsieve-services"

  prefix              = local.prefix
  resource_group_name = azurerm_resource_group.this.name
  location            = local.location
  tenant_id           = local.tenant_id

  oidc_issuer_url = module.aks.oidc_issuer_url
  vnet_id         = module.vnet.vnet_id
  nodes_subnet_id = module.vnet.nodes_subnet_id

  tags = local.tags
}

# ---------------------------------------------------------------------------
# Database
# ---------------------------------------------------------------------------

module "database" {
  source = "../../modules/azure-database"

  prefix              = local.prefix
  resource_group_name = azurerm_resource_group.this.name
  location            = local.location

  database_subnet_id  = module.vnet.database_subnet_id
  private_dns_zone_id = module.vnet.postgres_private_dns_zone_id
  key_vault_id        = module.services.key_vault_id

  tags = local.tags
}

# ---------------------------------------------------------------------------
# Ingress
# ---------------------------------------------------------------------------

module "ingress" {
  source = "../../modules/azure-user-ingress"

  prefix              = local.prefix
  resource_group_name = azurerm_resource_group.this.name
  location            = local.location
  cluster_id          = module.aks.cluster_id
  gateway_subnet_id   = module.vnet.gateway_subnet_id
  domain_name         = local.domain_name

  key_vault_id            = module.services.key_vault_id
  certificate_secret_name = local.certificate_secret_name

  tags = local.tags
}

# ---------------------------------------------------------------------------
# Release
# ---------------------------------------------------------------------------

module "presponsieve" {
  source = "../../modules/presponsieve-helm"

  domain_name      = local.domain_name
  chart_version    = local.chart_version
  image_tag        = local.image_tag
  create_namespace = true

  existing_secret = module.services.app_secret_name

  service_account = {
    create = false
    name   = module.services.kubernetes_service_account_name
  }

  # DATABASE_URL arrives through the application secret, so the DSN never
  # enters Terraform state. Put it in Key Vault as DATABASE-URL.
  database_url = null

  object_store = {
    backend      = "s3"
    bucket       = "artifacts"
    region       = local.location
    endpoint_url = "https://${module.services.artifacts_storage_account}.blob.core.windows.net"
  }

  oidc = {
    issuer_url = local.oidc_issuer_url
    client_id  = local.oidc_client_id
  }

  ingress = {
    class_name  = module.ingress.ingress_class_name
    annotations = module.ingress.ingress_annotations
  }
}
