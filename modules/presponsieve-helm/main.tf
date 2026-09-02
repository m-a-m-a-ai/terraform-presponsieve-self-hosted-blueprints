locals {
  # Non-secret environment, rendered by the chart into a ConfigMap.
  app_config = merge(
    {
      OPENAI_RESPONSES_MODEL = var.openai_model
      SIMULATION_SAMPLES     = tostring(var.simulation_samples)
      AUTH_COOKIE_SECURE     = "1"
      S3_PREFIX              = var.object_store.prefix
      KMS_BACKEND            = var.kms_backend
      LICENSE_PUBLIC_KEY     = var.license_public_key
      LICENSE_ENFORCEMENT    = var.license_enforcement
      LICENSE_VALIDATION_URL = var.license_validation_url
      TRANSCRIPTION_BACKEND  = var.transcription_backend
    },
    # Native GCS reads through Workload Identity and needs no S3 settings.
    var.object_store.backend == "gcs" ? {
      STORAGE_BACKEND = "gcs"
      } : {
      S3_FORCE_PATH_STYLE = tostring(var.object_store.force_path_style)
    },
    var.object_store.gcs_signer_service_account == null ? {} : {
      GCS_SIGNER_SERVICE_ACCOUNT = var.object_store.gcs_signer_service_account
    },
  )

  base_values = {
    # Without this the chart renders resources as <release>-<chart>, which is
    # "presponsieve". Pinning the full name keeps the Service,
    # Deployment, and certificate names readable.
    fullnameOverride = var.fullname_override

    image = merge(
      { repository = var.image_repository },
      var.image_tag == null ? {} : { tag = var.image_tag },
    )

    imagePullSecrets = [for s in var.image_pull_secrets : { name = s }]

    replicaCount = var.autoscaling.enabled ? var.replica_count : var.replica_count
    resources    = var.resources

    autoscaling = {
      enabled                        = var.autoscaling.enabled
      minReplicas                    = var.autoscaling.min_replicas
      maxReplicas                    = var.autoscaling.max_replicas
      targetCPUUtilizationPercentage = var.autoscaling.target_cpu
    }

    serviceAccount = {
      create      = var.service_account.create
      name        = var.service_account.name
      annotations = var.service_account.annotations
    }

    app = {
      existingSecret = var.existing_secret
      config         = local.app_config
    }

    # The chart never provisions backing services. These flags only select
    # whether the app wires itself to an in-cluster service or an external one.
    postgresql = { enabled = false }
    minio      = { enabled = false }
    keycloak   = { enabled = false }

    externalDatabase = {
      url = var.cloud_sql_proxy != null ? "" : coalesce(var.database_url, "")
    }

    externalObjectStore = {
      endpointUrl = var.object_store.endpoint_url
      bucket      = var.object_store.bucket
      region      = coalesce(var.object_store.region, "")
      # Keys stay empty. Every supported path uses workload identity.
      accessKeyId     = ""
      secretAccessKey = ""
    }

    ingress = local.ingress_values

    migration = { enabled = var.run_migration }
    backfill  = { enabled = var.run_backfill }
  }

  cloud_sql_values = var.cloud_sql_proxy == null ? {} : {
    cloudSqlProxy = {
      enabled                = true
      instanceConnectionName = var.cloud_sql_proxy.instance_connection_name
      iamUser                = var.cloud_sql_proxy.iam_user
      dbName                 = var.cloud_sql_proxy.database_name
      port                   = var.cloud_sql_proxy.port
      autoIamAuthn           = true
    }
  }

  oidc_values = var.oidc == null ? {} : {
    oidc = {
      issuerUrl = var.oidc.issuer_url
      clientId  = var.oidc.client_id
    }
  }

  iap_values = var.gke_iap == null ? {} : {
    gke = {
      iap = {
        enabled               = true
        oauthClientSecretName = var.gke_iap.oauth_client_secret_name
      }
      # The GCLB default backend timeout is 30s, shorter than a long analysis.
      # Past it the load balancer returns an HTML 502 the app never sees.
      backendConfig = {
        enabled            = true
        timeoutSec         = var.gke_iap.backend_timeout_seconds
        drainingTimeoutSec = 60
      }
    }
    service = {
      annotations = {
        # Container-native load balancing, so the GCE ingress targets the
        # ClusterIP service through NEGs without a NodePort.
        "cloud.google.com/neg" = jsonencode({ ingress = true })
      }
    }
  }

  values = merge(
    local.base_values,
    local.cloud_sql_values,
    local.oidc_values,
    local.iap_values,
    var.extra_values,
  )
}

# ---------------------------------------------------------------------------
# Ingress
# ---------------------------------------------------------------------------

locals {
  # Always the full shape. A conditional with two differently shaped objects
  # fails type checking, and the chart ignores the other keys when enabled is
  # false anyway.
  ingress_values = {
    enabled     = var.ingress.enabled
    className   = var.ingress.class_name
    host        = var.domain_name
    annotations = var.ingress.annotations

    tls = {
      enabled    = var.ingress.tls_secret_name != null
      secretName = coalesce(var.ingress.tls_secret_name, "")
    }

    managedCertificate = {
      enabled = var.ingress.managed_certificate
      name    = ""
      domains = var.ingress.managed_certificate ? [var.domain_name] : []
    }
  }
}

resource "kubernetes_namespace_v1" "this" {
  count = var.create_namespace ? 1 : 0

  metadata {
    name = var.namespace

    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
      "app.kubernetes.io/part-of"    = "presponsieve"
    }
  }
}

resource "helm_release" "presponsieve" {
  name       = var.release_name
  namespace  = var.namespace
  repository = var.chart_repository
  chart      = var.chart_name
  version    = var.chart_version

  values = [yamlencode(local.values)]

  timeout         = var.timeout
  wait            = true
  wait_for_jobs   = true
  atomic          = true
  cleanup_on_fail = true
  max_history     = 10

  depends_on = [kubernetes_namespace_v1.this]
}
