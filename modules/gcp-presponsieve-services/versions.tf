terraform {
  required_version = ">= 1.11"
  required_providers {
    google     = { source = "hashicorp/google", version = "~> 8.0" }
    helm       = { source = "hashicorp/helm", version = "~> 3.0, >= 3.0.2" }
    kubernetes = { source = "hashicorp/kubernetes", version = "~> 3.0" }
  }
}
