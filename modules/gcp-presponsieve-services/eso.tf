# External Secrets Operator projects the application secrets out of Secret
# Manager into the single Kubernetes secret the chart expects. Nothing
# sensitive passes through Terraform state or chart values.

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
  ]
}

resource "kubernetes_manifest" "secret_store" {
  manifest = {
    apiVersion = "external-secrets.io/v1beta1"
    kind       = "SecretStore"
    metadata = {
      name      = "gcp-secret-manager"
      namespace = var.namespace
    }
    spec = {
      provider = {
        gcpsm = {
          projectID = var.project_id
          auth = {
            workloadIdentity = {
              clusterLocation = var.region
              clusterName     = var.cluster_name
              serviceAccountRef = {
                name = var.service_account_name
              }
            }
          }
        }
      }
    }
  }

  depends_on = [
    helm_release.external_secrets,
    kubernetes_service_account_v1.app,
  ]
}

# One ExternalSecret producing one Kubernetes secret, because that is what the
# chart's app.existingSecret expects.
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
      secretStoreRef  = { name = "gcp-secret-manager", kind = "SecretStore" }
      target          = { name = "presponsieve-secrets", creationPolicy = "Owner" }
      data = [
        for k in var.secret_keys : {
          secretKey = k
          remoteRef = {
            key      = var.app_secret_id
            property = k
          }
        }
      ]
    }
  }

  depends_on = [kubernetes_manifest.secret_store]
}
