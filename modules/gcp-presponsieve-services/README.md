# gcp-presponsieve-services

Identity, secrets, and storage for a GCP deployment.

## The one service account

A single GCP service account is the only credential in the deployment. It:

- Is bound to the Kubernetes service account through Workload Identity.
- Holds `roles/cloudsql.client` and `roles/cloudsql.instanceUser`, which is how
  the Auth Proxy sidecar connects with no database password.
- Holds `roles/storage.objectAdmin` on the artifacts bucket.
- Reads the application secret from Secret Manager.
- Holds `roles/iam.serviceAccountTokenCreator` **on itself**, which is what lets
  it sign V4 download URLs. Workload Identity credentials carry no private key,
  so signing goes through IAM `signBlob`. This binding is easy to miss and the
  symptom is report downloads failing while everything else works.

No service account keys exist anywhere in this deployment.

## The one secret

The chart reads every sensitive value from a single Kubernetes secret. This
module creates one `ExternalSecret` that projects named keys out of a JSON
object you store in Secret Manager.

Create it yourself, so nothing sensitive touches Terraform:

```bash
gcloud secrets create presponsieve-secrets --replication-policy=automatic

jq -n --arg kek  "$(openssl rand -base64 32)" \
      --arg sess "$(openssl rand -base64 32)" \
      --arg idx  "$(openssl rand -base64 32)" \
      --arg tok  "$(openssl rand -base64 32)" \
      --arg lic  "$LICENSE_KEY" \
      '{APP_KEK:$kek, SESSION_SECRET:$sess, INDEX_PEPPER:$idx,
        AUTH_TOKEN_PEPPER:$tok, LICENSE_KEY:$lic}' \
  | gcloud secrets versions add presponsieve-secrets --data-file=-
```

Back `APP_KEK` up somewhere other than this project. Losing it makes every
encrypted row unrecoverable, and no restore will bring it back.

To enable narrative rendering, add `OPENAI_API_KEY` to the JSON object and to
`secret_keys`.

## Renewal is a secret update

Add a new version to the Secret Manager secret. External Secrets picks it up
within `secret_refresh_interval` and Reloader restarts the pods. No new image,
no chart change.

## Transcription

`enable_transcription = true` grants `roles/speech.client` for audio uploads
with speaker diarization. You must also enable the Speech-to-Text API on the
project and set `transcription_backend = "gcp"` on the Helm module.
