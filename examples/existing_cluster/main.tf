# ---------------------------------------------------------------------------
# Helm-only deployment into a cluster your platform team already runs.
#
# No cloud infrastructure is provisioned. This is the most common enterprise
# path, because platform teams rarely let a vendor's Terraform create VPCs.
#
# You arrange, in advance:
#   - a Kubernetes cluster you can reach (1.27+)
#   - a Postgres 14+ instance the cluster can reach
#   - an object storage bucket
#   - an ingress controller and a TLS certificate
#   - an OIDC issuer, or an identity-aware proxy in front
#   - the application secret (see below)
# ---------------------------------------------------------------------------

locals {
  namespace   = "presponsieve"
  domain_name = "app.internal.acme.com"

  chart_version = "0.1.0"
  image_tag     = "0.1.0"

  # Created out of band. See the README.
  app_secret = "presponsieve-secrets"

  oidc_issuer_url = "https://login.acme.com/oauth2/default"
  oidc_client_id  = "0oa1b2c3d4"

  artifacts_bucket = "acme-presponsieve-artifacts"
  s3_endpoint      = "" # set for MinIO or another S3-compatible target
  region           = "us-east-1"

  ingress_class = "nginx"
  tls_secret    = "presponsieve-tls"
}

module "presponsieve" {
  source = "../../modules/presponsieve-helm"

  namespace        = local.namespace
  create_namespace = true

  domain_name   = local.domain_name
  chart_version = local.chart_version
  image_tag     = local.image_tag

  # Every sensitive value lives in this one secret, including DATABASE_URL.
  # Nothing sensitive appears in this file or in Terraform state.
  existing_secret = local.app_secret

  service_account = {
    create = true
  }

  object_store = {
    backend      = "s3"
    bucket       = local.artifacts_bucket
    region       = local.region
    endpoint_url = local.s3_endpoint
  }

  oidc = {
    issuer_url = local.oidc_issuer_url
    client_id  = local.oidc_client_id
  }

  ingress = {
    class_name      = local.ingress_class
    tls_secret_name = local.tls_secret
    annotations = {
      # The app accepts transcripts and audio, which go well past the nginx
      # 1MB default. Without this you get an nginx HTML 413 the app never sees.
      "nginx.ingress.kubernetes.io/proxy-body-size"    = "100m"
      "nginx.ingress.kubernetes.io/proxy-read-timeout" = "600"
      "nginx.ingress.kubernetes.io/proxy-send-timeout" = "600"
    }
  }

  autoscaling = {
    enabled      = true
    min_replicas = 2
    max_replicas = 5
  }
}
