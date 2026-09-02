# Copy this file to provider.tf and fill in your values.
#   cp provider.example.tf provider.tf

provider "azurerm" {
  subscription_id = local.subscription_id

  features {
    key_vault {
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = true
    }
  }
}

provider "kubernetes" {
  host                   = module.aks.host
  client_certificate     = base64decode(module.aks.client_certificate)
  client_key             = base64decode(module.aks.client_key)
  cluster_ca_certificate = base64decode(module.aks.cluster_ca_certificate)
}

provider "helm" {
  kubernetes = {
    host                   = module.aks.host
    client_certificate     = base64decode(module.aks.client_certificate)
    client_key             = base64decode(module.aks.client_key)
    cluster_ca_certificate = base64decode(module.aks.cluster_ca_certificate)
  }
}

# Optional but recommended once more than one person touches this deployment.
# terraform {
#   backend "azurerm" {
#     resource_group_name  = "acme-terraform"
#     storage_account_name = "acmetfstate"
#     container_name       = "tfstate"
#     key                  = "presponsieve.tfstate"
#   }
# }
