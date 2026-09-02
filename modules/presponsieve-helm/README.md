# presponsieve-helm

Cloud-agnostic module that installs the Presponsieve chart from
`oci://ghcr.io/m-a-m-a-ai/charts/presponsievelite`.

It provisions no infrastructure. It assumes a reachable cluster, a Postgres
instance, an object storage bucket, and a Kubernetes secret holding the
application secrets.

## Resource naming

The chart names resources `<release>-<chart>`. With both set to `presponsieve`
that would render `presponsieve`, so the module sets
`fullnameOverride` and the Service is simply `presponsieve`. Override
`fullname_override` if you run more than one release in a namespace.

## What the chart actually deploys

One stateless FastAPI Deployment serving both UI and API on container port
8080, behind a Service on port 80. A migration Job runs `alembic upgrade head`
as a pre-install and pre-upgrade Helm hook. An optional backfill Job encrypts
pre-existing plaintext rows.

That is the whole workload. Postgres, object storage, and your identity
provider sit outside the chart and are yours to supply.

## The one secret

The chart reads every sensitive value from a single Kubernetes secret named by
`existing_secret`. Create it out of band, or have a cloud services module sync
it from your secret manager. Nothing sensitive passes through Terraform.

| Key | Required | Purpose |
| --- | --- | --- |
| `APP_KEK` | Yes | Envelope-encryption key. Losing it makes encrypted data unrecoverable |
| `SESSION_SECRET` | Yes | Signs the session cookie. Required for more than one replica |
| `INDEX_PEPPER` | Yes | HMAC for blind indexes on searchable columns |
| `AUTH_TOKEN_PEPPER` | Yes | HMAC for hashing login tokens at rest |
| `LICENSE_KEY` | Yes | Signed license token |
| `MODEL_CONTENT_KEY` | No | Decrypts the model assets. Not needed when the license carries it |
| `OPENAI_API_KEY` | No | Enables narrative rendering and chat |
| `ACCESS_TOKENS` | No | Break-glass login tokens. Disable after SSO works |
| `GOOGLE_CLIENT_ID` | No | Google Sign-In |

Generate the four crypto values with `openssl rand -base64 32` and back them up
somewhere other than the cluster.

## Usage

```hcl
module "presponsieve" {
  source = "github.com/m-a-m-a-ai/terraform-presponsieve-self-hosted-blueprints//modules/presponsieve-helm"

  domain_name     = "app.acme.com"
  chart_version   = "0.1.0"
  existing_secret = "presponsieve-secrets"

  object_store = {
    backend = "s3"
    bucket  = "acme-presponsieve-artifacts"
    region  = "us-east-1"
  }

  database_url = "postgresql+psycopg2://presponsieve@db.internal:5432/presponsieve"

  oidc = {
    issuer_url = "https://login.acme.com/oauth2/default"
    client_id  = "0oa1b2c3d4"
  }

  ingress = {
    class_name      = "nginx"
    tls_secret_name = "presponsieve-tls"
  }
}
```

## Database: two paths

**Cloud SQL Auth Proxy, on GKE.** Set `cloud_sql_proxy` and leave `database_url`
null. The sidecar authenticates with the pod's Workload Identity and connects
with IAM database auth, so no database password exists anywhere. This is the
better option and needs Kubernetes 1.29 or later for native sidecars.

**A DSN.** Set `database_url`. It lands in Terraform state, so source it from a
variable your secret manager populates rather than writing it in a `.tf` file.

## Object storage: two backends

`backend = "gcs"` uses native GCS through Workload Identity. Supply only the
bucket. Set `gcs_signer_service_account` to the GSA that signs V4 URLs; it needs
`roles/iam.serviceAccountTokenCreator` on itself, because Workload Identity
credentials carry no private key.

`backend = "s3"` covers S3 and any S3-compatible target. Use an IRSA-annotated
service account rather than static keys.

## Pin your chart version

`chart_version` defaults to null, which resolves to whatever is newest at apply
time. Pin it. Moving that string is the upgrade, and it shows up in review, in
history, and in `terraform plan`.
