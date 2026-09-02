# Presponsieve self-hosted blueprints

Terraform modules and worked examples for deploying
[Presponsieve](https://github.com/m-a-m-a-ai/presponsievelite-selfhosted)
into your own cloud account. GKE, EKS, and a generic path for everything else.

These blueprints provision infrastructure and then install the published chart
from `oci://ghcr.io/m-a-m-a-ai/charts/presponsievelite`. The chart itself, and
its own documentation, live in the self-hosting repository.

## What gets deployed

One stateless FastAPI Deployment serving UI and API on port 8080, behind a
Service on port 80, plus a migration Job that runs as a pre-install and
pre-upgrade Helm hook.

Three backing services sit outside the chart and are provisioned by these
modules: PostgreSQL, an object storage bucket for report artifacts, and your
identity provider or an identity-aware proxy.

## Where your data goes

Analysis runs inside your cluster. Text you submit is scored locally, and the
simulation engine produces reproducible percentile vectors without contacting
anyone.

Narrative rendering is optional. When `OPENAI_API_KEY` is present in the
application secret, the app makes one OpenAI call per turn to convert
already-computed vectors into prose, under your own API key and your own
agreement with OpenAI. Leave the key unset and the deployment runs with no
third-party egress, returning the same structured output without the prose.

`TRANSCRIPTION_BACKEND = "gcp"` adds Google Speech-to-Text for audio uploads and
is off by default.

The exact egress surface is in [`guides/networking.md`](guides/networking.md).

## Repository layout

- [`modules/`](modules) — building blocks, one set per cloud, plus the
  cloud-agnostic [`presponsieve-helm`](modules/presponsieve-helm) module.
- [`examples/`](examples) — copy-paste starting points. **Start here.**
- [`guides/`](guides) — topics that apply across clouds.

## Requirements

- [Terraform](https://developer.hashicorp.com/terraform/install) **>= 1.11**
- [Helm](https://helm.sh/docs/intro/install) **>= 3.8**, with OCI support
- Kubernetes **1.27+**, or **1.29+** to use the Cloud SQL Auth Proxy sidecar
- `kubectl`, and your cloud CLI authenticated
- A `LICENSE_KEY`, purchased separately

## Choosing an example

| Example | Use when |
| --- | --- |
| [`existing_cluster`](examples/existing_cluster) | Your platform team owns the cluster. **Most common enterprise path.** |
| [`gcp_all_inclusive`](examples/gcp_all_inclusive) | Empty GCP project. Cloud SQL with IAM auth, native GCS, IAP. |
| [`aws_all_inclusive`](examples/aws_all_inclusive) | Empty AWS account. RDS, S3, ALB, external OIDC. |
| [`azure_all_inclusive`](examples/azure_all_inclusive) | Azure. The generic external-everything path. |

## Getting started

```bash
cd examples/gcp_all_inclusive
cp provider.example.tf provider.tf
# edit the locals block at the top of main.tf
terraform init
terraform plan
terraform apply
```

Each example has one `locals` block holding everything you need to change.

## The one secret

The chart reads every sensitive value from a single Kubernetes secret. Create it
before you apply, so nothing sensitive ever reaches Terraform state.

| Key | Required | Purpose |
| --- | --- | --- |
| `APP_KEK` | Yes | Envelope-encryption key |
| `SESSION_SECRET` | Yes | Signs the session cookie. Required for >1 replica |
| `INDEX_PEPPER` | Yes | HMAC for blind indexes |
| `AUTH_TOKEN_PEPPER` | Yes | HMAC for token hashing at rest |
| `LICENSE_KEY` | Yes | Signed license token |
| `DATABASE_URL` | Usually | Full DSN. Not needed with the Cloud SQL Auth Proxy |
| `MODEL_CONTENT_KEY` | No | Decrypts model assets, when the license does not carry it |
| `OPENAI_API_KEY` | No | Enables narrative rendering and chat |
| `ACCESS_TOKENS` | No | Break-glass login tokens. Disable after SSO works |
| `GOOGLE_CLIENT_ID` | No | Google Sign-In |

Generate the four crypto values with `openssl rand -base64 32`.

> **`APP_KEK` is not recoverable.** Losing it makes every encrypted row
> permanently unreadable, and no database restore brings it back. Back it up
> somewhere that outlives the cluster.

Each cloud's services module syncs this secret from your cloud secret manager
through External Secrets, so the values never appear in a `.tf` file, in state,
or in `helm get values`.

## Verifying a deployment

A health check only proves the pod started. Run one analysis end to end instead.
It exercises the database write, the object storage upload, and signed-URL
retrieval in a single flow.

```bash
kubectl port-forward -n presponsieve svc/presponsieve 8080:80
curl -s localhost:8080/healthz    # {"status":"ok"}
```

Then sign in, run an analysis, and confirm the report, radar image, and PDF come
back.

## Support

Issues with these blueprints belong in this repository. Questions about the
application or the chart belong in
[`presponsievelite-selfhosted`](https://github.com/m-a-m-a-ai/presponsievelite-selfhosted).
