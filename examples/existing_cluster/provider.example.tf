# Copy this file to provider.tf and fill in your values.
#   cp provider.example.tf provider.tf
#
# This example assumes your kubeconfig already points at the right cluster.
# Verify before applying:
#   kubectl config current-context

provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "acme-prod"
}

provider "helm" {
  kubernetes = {
    config_path    = "~/.kube/config"
    config_context = "acme-prod"
  }
}
