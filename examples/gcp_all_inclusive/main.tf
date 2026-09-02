# ---------------------------------------------------------------------------
# Edit this block. Nothing else in the file needs to change for a standard
# deployment.
#
# This example reproduces the deployment described by the chart's
# values-gke.example.yaml: Cloud SQL with IAM auth and no password, native GCS
# through Workload Identity, a GCE ingress with a Google-managed certificate,
# and Identity-Aware Proxy as the sign-in gateway.
# ---------------------------------------------------------------------------

locals {
  prefix      = "presponsieve"
  project_id  = "acme-presponsieve"
  region      = "us-central1"
  domain_name = "app.acme.com"

  # Secret Manager secret holding the application secrets as JSON. Create it
  # before applying; see the services module README for the exact command.
  app_secret = "presponsieve-secrets"

  # Pin this.
  chart_version = "0.1.0"
  image_tag     = "0.1.0"

  # Kubernetes secret holding the IAP OAuth client, with client_id and
  # client_secret keys. Create the OAuth client in the console first.
  iap_oauth_secret = "presponsieve-iap-oauth"

  # Add your VPN or bastion range. Without it you cannot reach the control plane.
  admin_cidrs = [
    # { cidr_block = "203.0.113.0/24", display_name = "corp-vpn" },
  ]

  labels = {
    application = "presponsieve"
    managed-by  = "terraform"
  }
}

module "vpc" {
  source = "../../modules/gcp-vpc"

  prefix     = local.prefix
  project_id = local.project_id
  region     = local.region
  labels     = local.labels
}

module "gke" {
  source = "../../modules/gcp-gke"

  prefix     = local.prefix
  project_id = local.project_id
  region     = local.region

  network_id          = module.vpc.network_id
  subnet_id           = module.vpc.subnet_id
  pods_range_name     = module.vpc.pods_range_name
  services_range_name = module.vpc.services_range_name

  master_authorized_networks = local.admin_cidrs
  labels                     = local.labels
}

# Identity and secrets come before the database, because the Cloud SQL IAM user
# is the application service account.
module "services" {
  source = "../../modules/gcp-presponsieve-services"

  prefix     = local.prefix
  project_id = local.project_id
  region     = local.region

  cluster_name           = module.gke.cluster_name
  workload_identity_pool = module.gke.workload_identity_pool

  app_secret_id = local.app_secret

  labels = local.labels
}

module "database" {
  source = "../../modules/gcp-database"

  prefix     = local.prefix
  project_id = local.project_id
  region     = local.region

  network_id                 = module.vpc.network_id
  private_service_connection = module.vpc.private_service_connection
  app_service_account_email  = module.services.service_account_email

  labels = local.labels
}

module "ingress" {
  source = "../../modules/gcp-user-ingress"

  prefix      = local.prefix
  project_id  = local.project_id
  domain_name = local.domain_name

  labels = local.labels
}

module "presponsieve" {
  source = "../../modules/presponsieve-helm"

  domain_name      = local.domain_name
  chart_version    = local.chart_version
  image_tag        = local.image_tag
  create_namespace = true

  existing_secret = module.services.app_secret_name

  # The service account is created by the services module with the workload
  # identity annotation already on it, so the chart must not create its own.
  service_account = {
    create = false
    name   = module.services.kubernetes_service_account_name
  }

  # Password-less. The proxy authenticates with the pod's Workload Identity.
  cloud_sql_proxy = {
    instance_connection_name = module.database.connection_name
    iam_user                 = module.database.iam_user
    database_name            = module.database.database_name
  }

  object_store = {
    backend                    = "gcs"
    bucket                     = module.services.artifacts_bucket
    region                     = local.region
    gcs_signer_service_account = module.services.gcs_signer_service_account
  }

  # Google authenticates every request before it reaches the app. No in-app
  # login screen, and no OIDC issuer to configure.
  gke_iap = {
    oauth_client_secret_name = local.iap_oauth_secret
  }

  ingress = {
    class_name          = "gce"
    managed_certificate = true
    annotations         = module.ingress.ingress_annotations
  }
}
