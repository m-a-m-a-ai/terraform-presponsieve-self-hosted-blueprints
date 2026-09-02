terraform {
  required_version = ">= 1.11"
  required_providers {
    aws        = { source = "hashicorp/aws", version = "~> 6.0" }
    helm       = { source = "hashicorp/helm", version = "~> 3.0, >= 3.0.2" }
    http       = { source = "hashicorp/http", version = ">= 3.4" }
    kubernetes = { source = "hashicorp/kubernetes", version = "~> 3.0" }
  }
}
