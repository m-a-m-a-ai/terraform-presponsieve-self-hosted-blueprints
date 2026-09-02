# Copy this file to provider.tf and fill in your values.
#   cp provider.example.tf provider.tf

provider "google" {
  project = local.project_id
  region  = local.region
}

data "google_client_config" "current" {}

provider "kubernetes" {
  host                   = "https://${module.gke.endpoint}"
  token                  = data.google_client_config.current.access_token
  cluster_ca_certificate = base64decode(module.gke.cluster_ca_certificate)
}

provider "helm" {
  kubernetes = {
    host                   = "https://${module.gke.endpoint}"
    token                  = data.google_client_config.current.access_token
    cluster_ca_certificate = base64decode(module.gke.cluster_ca_certificate)
  }
}

# Optional but recommended once more than one person touches this deployment.
# terraform {
#   backend "gcs" {
#     bucket = "acme-terraform-state"
#     prefix = "presponsieve"
#   }
# }
