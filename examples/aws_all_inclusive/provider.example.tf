# Copy this file to provider.tf and fill in your values.
#   cp provider.example.tf provider.tf

provider "aws" {
  region = local.region

  default_tags {
    tags = local.tags
  }
}

data "aws_eks_cluster_auth" "this" {
  name = module.eks.cluster_name
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_ca_certificate)
  token                  = data.aws_eks_cluster_auth.this.token
}

provider "helm" {
  kubernetes = {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_ca_certificate)
    token                  = data.aws_eks_cluster_auth.this.token
  }
}

# Optional but recommended once more than one person touches this deployment.
# terraform {
#   backend "s3" {
#     bucket       = "acme-terraform-state"
#     key          = "presponsieve/terraform.tfstate"
#     region       = "us-east-1"
#     encrypt      = true
#     use_lockfile = true
#   }
# }
