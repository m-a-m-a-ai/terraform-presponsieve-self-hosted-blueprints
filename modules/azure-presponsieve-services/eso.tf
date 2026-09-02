# External Secrets projects Key Vault secrets into the single Kubernetes secret
# the chart expects.

resource "azurerm_user_assigned_identity" "external_secrets" {
  name                = "${var.prefix}-eso"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}

resource "azurerm_federated_identity_credential" "external_secrets" {
  name                      = "${var.prefix}-eso"
  user_assigned_identity_id = azurerm_user_assigned_identity.external_secrets.id
  audience                  = ["api://AzureADTokenExchange"]
  issuer                    = var.oidc_issuer_url
  subject                   = "system:serviceaccount:external-secrets:external-secrets"
}

resource "azurerm_role_assignment" "external_secrets" {
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.external_secrets.principal_id
}

resource "helm_release" "external_secrets" {
  name             = "external-secrets"
  namespace        = "external-secrets"
  create_namespace = true
  repository       = "https://charts.external-secrets.io"
  chart            = "external-secrets"
  version          = "0.10.7"

  set = [
    {
      name  = "installCRDs"
      value = "true"
    },
    {
      name  = "podLabels.azure\\.workload\\.identity/use"
      value = "true"
    },
    {
      name  = "serviceAccount.annotations.azure\\.workload\\.identity/client-id"
      value = azurerm_user_assigned_identity.external_secrets.client_id
    },
  ]
}

resource "kubernetes_manifest" "secret_store" {
  manifest = {
    apiVersion = "external-secrets.io/v1beta1"
    kind       = "SecretStore"
    metadata = {
      name      = "azure-key-vault"
      namespace = var.namespace
    }
    spec = {
      provider = {
        azurekv = {
          authType = "WorkloadIdentity"
          vaultUrl = azurerm_key_vault.this.vault_uri
          serviceAccountRef = {
            name      = "external-secrets"
            namespace = "external-secrets"
          }
        }
      }
    }
  }

  depends_on = [helm_release.external_secrets]
}

resource "kubernetes_manifest" "app_secrets" {
  manifest = {
    apiVersion = "external-secrets.io/v1beta1"
    kind       = "ExternalSecret"
    metadata = {
      name      = "presponsieve-secrets"
      namespace = var.namespace
    }
    spec = {
      refreshInterval = var.secret_refresh_interval
      secretStoreRef  = { name = "azure-key-vault", kind = "SecretStore" }
      target          = { name = "presponsieve-secrets", creationPolicy = "Owner" }
      data = [
        for env_name, vault_name in local.secret_map : {
          secretKey = env_name
          remoteRef = { key = vault_name }
        }
      ]
    }
  }

  depends_on = [kubernetes_manifest.secret_store]
}
