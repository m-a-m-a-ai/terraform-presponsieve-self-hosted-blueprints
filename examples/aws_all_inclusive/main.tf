# ---------------------------------------------------------------------------
# Edit this block. Nothing else in the file needs to change for a standard
# deployment.
# ---------------------------------------------------------------------------

locals {
  prefix      = "presponsieve"
  region      = "us-east-1"
  domain_name = "app.acme.com"

  # Secrets Manager secret holding the application secrets as JSON. Create it
  # before applying; see the services module README for the exact command.
  app_secret = "presponsieve/app"

  # Pin these. See guides/upgrades.md.
  chart_version = "0.1.0"
  image_tag     = "0.1.0"

  # Your identity provider. EKS has no IAP equivalent, so SSO is OIDC.
  oidc_issuer_url = "https://acme.okta.com/oauth2/default"
  oidc_client_id  = "0oa1b2c3d4e5f6"

  # Add your VPN egress address. Empty means the API server is private only.
  admin_cidrs = [
    # "203.0.113.42/32",
  ]

  tags = {
    Application = "presponsieve"
    ManagedBy   = "terraform"
  }
}

# ---------------------------------------------------------------------------
# Network
# ---------------------------------------------------------------------------

module "vpc" {
  source = "../../modules/aws-vpc"

  prefix = local.prefix
  tags   = local.tags
}

# ---------------------------------------------------------------------------
# Cluster
# ---------------------------------------------------------------------------

module "eks" {
  source = "../../modules/aws-eks"

  prefix             = local.prefix
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids

  public_access_cidrs = local.admin_cidrs
  tags                = local.tags
}

# ---------------------------------------------------------------------------
# Database
# ---------------------------------------------------------------------------

module "database" {
  source = "../../modules/aws-database"

  prefix             = local.prefix
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids

  allowed_security_group_ids = [module.eks.node_security_group_id]

  tags = local.tags
}

# ---------------------------------------------------------------------------
# Identity, secrets, storage
# ---------------------------------------------------------------------------

module "services" {
  source = "../../modules/aws-presponsieve-services"

  prefix = local.prefix

  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = module.eks.oidc_provider_url

  app_secret_name = local.app_secret

  tags = local.tags
}

# ---------------------------------------------------------------------------
# Ingress
# ---------------------------------------------------------------------------

module "ingress" {
  source = "../../modules/aws-user-ingress"

  prefix       = local.prefix
  vpc_id       = module.vpc.vpc_id
  cluster_name = module.eks.cluster_name
  domain_name  = local.domain_name

  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = module.eks.oidc_provider_url

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

  # DATABASE_URL arrives through the application secret rather than a variable,
  # so the DSN never enters Terraform state. Put it in the Secrets Manager JSON
  # alongside the crypto material.
  database_url = null

  object_store = {
    backend = "s3"
    bucket  = module.services.artifacts_bucket
    region  = local.region
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
