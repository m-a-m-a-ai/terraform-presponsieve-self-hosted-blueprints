variable "release_name" {
  description = <<-EOT
    Helm release name. Note that the chart's resources are named
    `<fullname>`, which this module pins with `fullname_override`. The
    release name itself only appears in `helm list` output.
  EOT
  type        = string
  default     = "presponsieve"
}

variable "fullname_override" {
  description = <<-EOT
    Name the chart gives its resources. Left at the chart default, resources
    would be named <release>-<chart>, which duplicates the word. Pinning it
    makes the Service simply "presponsieve".
  EOT
  type        = string
  default     = "presponsieve"
}

variable "namespace" {
  description = "Namespace to deploy into."
  type        = string
  default     = "presponsieve"
}

variable "create_namespace" {
  description = "Whether this module creates the namespace."
  type        = bool
  default     = true
}

# ---------------------------------------------------------------------------
# Chart and image
# ---------------------------------------------------------------------------

variable "chart_repository" {
  description = "OCI repository hosting the chart."
  type        = string
  default     = "oci://ghcr.io/m-a-m-a-ai/charts"
}

variable "chart_name" {
  description = "Chart name."
  type        = string
  default     = "presponsieve"
}

variable "chart_version" {
  description = <<-EOT
    Chart version to install. Pin this. Null resolves to whatever is newest at
    apply time, which makes two applies a week apart install different software
    with nothing in your Terraform to explain it.
  EOT
  type        = string
  default     = null
}

variable "image_repository" {
  description = <<-EOT
    Container image. Defaults to the public GHCR image. Override to pull from
    your own registry, for example
    <REGION>-docker.pkg.dev/<PROJECT>/<REPO>/presponsieve.
  EOT
  type        = string
  default     = "ghcr.io/m-a-m-a-ai/presponsieve"
}

variable "image_tag" {
  description = "Image tag. Falls back to the chart's appVersion when null."
  type        = string
  default     = null
}

variable "image_pull_secrets" {
  description = "Existing pull secrets, if the image is private to you."
  type        = list(string)
  default     = []
}

# ---------------------------------------------------------------------------
# Secrets
#
# The chart takes ONE secret holding every sensitive value. Create it out of
# band, or let a cloud services module sync it from your secret manager, then
# name it here. Nothing sensitive passes through Terraform.
#
# Required keys:  APP_KEK, SESSION_SECRET, INDEX_PEPPER, AUTH_TOKEN_PEPPER,
#                 LICENSE_KEY
# Optional keys:  MODEL_CONTENT_KEY, OPENAI_API_KEY, ACCESS_TOKENS,
#                 GOOGLE_CLIENT_ID
# ---------------------------------------------------------------------------

variable "existing_secret" {
  description = "Name of the Kubernetes secret holding the application secrets."
  type        = string
}

# ---------------------------------------------------------------------------
# Ingress
# ---------------------------------------------------------------------------

variable "domain_name" {
  description = "Host users reach the application on."
  type        = string
}

variable "ingress" {
  description = <<-EOT
    Ingress wiring. `class_name` is nginx, gce, or alb depending on your
    controller. Set `managed_certificate` on GKE to have the chart render a
    ManagedCertificate; set `tls_secret_name` everywhere else.
  EOT
  type = object({
    enabled             = optional(bool, true)
    class_name          = optional(string, "nginx")
    annotations         = optional(map(string), {})
    tls_secret_name     = optional(string)
    managed_certificate = optional(bool, false)
  })
  default = {}
}

# ---------------------------------------------------------------------------
# Backing services
# ---------------------------------------------------------------------------

variable "database_url" {
  description = <<-EOT
    Full SQLAlchemy DSN, for example
    postgresql+psycopg2://user:pass@host:5432/presponsieve.

    Leave null when using the Cloud SQL Auth Proxy, which supplies DATABASE_URL
    itself. Anything you put here lands in Terraform state, so prefer the proxy
    on GCP and a secret-sourced DSN elsewhere.
  EOT
  type        = string
  default     = null
  sensitive   = true
}

variable "cloud_sql_proxy" {
  description = <<-EOT
    Cloud SQL Auth Proxy sidecar. Password-less: the pod authenticates with its
    Workload Identity and connects with IAM database auth, so no database
    credential exists anywhere. Requires Kubernetes 1.29 or later for native
    sidecars. Takes precedence over database_url.
  EOT
  type = object({
    instance_connection_name = string # PROJECT:REGION:INSTANCE
    iam_user                 = string # GSA email with .gserviceaccount.com stripped
    database_name            = optional(string, "presponsieve")
    port                     = optional(number, 5432)
  })
  default = null
}

variable "object_store" {
  description = <<-EOT
    Report artifact storage. On GCP set backend to "gcs" and supply only the
    bucket: the pod uses Workload Identity and needs no keys. Elsewhere use
    "s3" with an IRSA-annotated service account, or supply an endpoint for a
    MinIO or other S3-compatible target.
  EOT
  type = object({
    backend                    = optional(string, "s3") # s3 or gcs
    bucket                     = string
    region                     = optional(string)
    endpoint_url               = optional(string, "")
    prefix                     = optional(string, "reports")
    force_path_style           = optional(bool, true)
    gcs_signer_service_account = optional(string)
  })
}

# ---------------------------------------------------------------------------
# Identity
# ---------------------------------------------------------------------------

variable "oidc" {
  description = <<-EOT
    OIDC issuer and client. Leave null when fronting the app with an
    identity-aware proxy instead.
  EOT
  type = object({
    issuer_url = string
    client_id  = string
  })
  default = null
}

variable "gke_iap" {
  description = <<-EOT
    Identity-Aware Proxy as the sign-in gateway. Google authenticates every
    request before it reaches the app, which then trusts the forwarded
    x-goog-authenticated-user-email header.

    Only safe when the app is reachable ONLY through the proxy. If a pod can be
    reached directly, that header is client-supplied and the trust is misplaced.
    Requires the GCE ingress class.
  EOT
  type = object({
    oauth_client_secret_name = string
    backend_timeout_seconds  = optional(number, 600)
  })
  default = null
}

# ---------------------------------------------------------------------------
# Application configuration
# ---------------------------------------------------------------------------

variable "kms_backend" {
  description = <<-EOT
    Backend holding the key-encryption key for envelope encryption:
    "k8s" reads APP_KEK from the application secret, which is the documented
    default. "aws", "gcp", and "vault" delegate to an external KMS.
  EOT
  type        = string
  default     = "k8s"

  validation {
    condition     = contains(["k8s", "aws", "gcp", "vault"], var.kms_backend)
    error_message = "kms_backend must be one of: k8s, aws, gcp, vault."
  }
}

variable "license_public_key" {
  description = <<-EOT
    Base64 Ed25519 public key that verifies your license token. Published with
    each release. Leaving it blank disables the license gate entirely, which is
    a development configuration.
  EOT
  type        = string
  default     = ""
}

variable "license_enforcement" {
  description = "enforce, warn, or disabled."
  type        = string
  default     = "enforce"

  validation {
    condition     = contains(["enforce", "warn", "disabled"], var.license_enforcement)
    error_message = "license_enforcement must be one of: enforce, warn, disabled."
  }
}

variable "license_validation_url" {
  description = <<-EOT
    Optional revocation-check endpoint. Leave blank for fully offline
    validation, which is the default and requires no egress.
  EOT
  type        = string
  default     = ""
}

variable "openai_model" {
  description = <<-EOT
    Model used for narrative rendering. Only consulted when OPENAI_API_KEY is
    present in the application secret. Scoring and simulation are local either
    way.
  EOT
  type        = string
  default     = "gpt-4o-mini"
}

variable "simulation_samples" {
  description = "Monte Carlo sample count for the simulation engine."
  type        = number
  default     = 1000
}

variable "transcription_backend" {
  description = <<-EOT
    "gcp" enables Google Cloud Speech-to-Text with speaker diarization for audio
    uploads. Requires the Speech-to-Text API and roles/speech.client on the
    workload identity. "disabled" makes the audio endpoint decline and point
    users at text upload.
  EOT
  type        = string
  default     = "disabled"
}

# ---------------------------------------------------------------------------
# Sizing
# ---------------------------------------------------------------------------

variable "replica_count" {
  description = "Replicas when autoscaling is off."
  type        = number
  default     = 2
}

variable "autoscaling" {
  description = <<-EOT
    Horizontal pod autoscaling on CPU. Set SESSION_SECRET in the application
    secret before running more than one replica, or an SSO callback landing on
    a different pod than the one that started the flow will fail.
  EOT
  type = object({
    enabled      = optional(bool, true)
    min_replicas = optional(number, 2)
    max_replicas = optional(number, 5)
    target_cpu   = optional(number, 75)
  })
  default = {}
}

variable "resources" {
  description = "Requests and limits for the application container."
  type = object({
    requests = object({ cpu = string, memory = string })
    limits   = object({ cpu = string, memory = string })
  })
  default = {
    requests = { cpu = "250m", memory = "512Mi" }
    limits   = { cpu = "1", memory = "1Gi" }
  }
}

variable "service_account" {
  description = <<-EOT
    Service account for the workload. Annotate it for workload identity so the
    pod reaches storage and Cloud SQL without static keys.
  EOT
  type = object({
    create      = optional(bool, true)
    name        = optional(string, "")
    annotations = optional(map(string), {})
  })
  default = {}
}

variable "run_migration" {
  description = <<-EOT
    Run alembic as a pre-install and pre-upgrade hook. Leave on. An unreachable
    database then fails the install cleanly instead of starting pods against a
    schema that is not there.
  EOT
  type        = bool
  default     = true
}

variable "run_backfill" {
  description = <<-EOT
    One-off job that encrypts pre-existing plaintext rows. Idempotent. Enable
    once after provisioning a KEK, then set it back to false.
  EOT
  type        = bool
  default     = false
}

# ---------------------------------------------------------------------------
# Escape hatch
# ---------------------------------------------------------------------------

variable "extra_values" {
  description = <<-EOT
    Chart values merged last, overriding everything this module sets. Use for
    settings not yet exposed as typed variables. Anything you depend on here
    long term should be promoted, so open an issue.
  EOT
  type        = any
  default     = {}
}

variable "timeout" {
  description = "Seconds to wait for the release to become ready."
  type        = number
  default     = 900
}
