# External Secrets projects the application secrets out of Secrets Manager into
# the single Kubernetes secret the chart expects.

resource "aws_iam_role" "external_secrets" {
  name = "${var.prefix}-external-secrets"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = var.oidc_provider_arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${var.oidc_provider_url}:sub" = "system:serviceaccount:external-secrets:external-secrets"
          "${var.oidc_provider_url}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "external_secrets" {
  name = "${var.prefix}-external-secrets"
  role = aws_iam_role.external_secrets.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"]
      Resource = ["arn:aws:secretsmanager:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:secret:${var.app_secret_name}-*"]
    }]
  })
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
      name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
      value = aws_iam_role.external_secrets.arn
    },
  ]
}

resource "kubernetes_manifest" "secret_store" {
  manifest = {
    apiVersion = "external-secrets.io/v1beta1"
    kind       = "SecretStore"
    metadata = {
      name      = "aws-secrets-manager"
      namespace = var.namespace
    }
    spec = {
      provider = {
        aws = {
          service = "SecretsManager"
          region  = data.aws_region.current.region
          auth = {
            jwt = {
              serviceAccountRef = { name = "external-secrets", namespace = "external-secrets" }
            }
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
      secretStoreRef  = { name = "aws-secrets-manager", kind = "SecretStore" }
      target          = { name = "presponsieve-secrets", creationPolicy = "Owner" }
      data = [
        for k in var.secret_keys : {
          secretKey = k
          remoteRef = {
            key      = var.app_secret_name
            property = k
          }
        }
      ]
    }
  }

  depends_on = [kubernetes_manifest.secret_store]
}
