# aws-presponsieve-services

Identity, secrets, and storage for an EKS deployment.

## The one secret

The chart reads every sensitive value from a single Kubernetes secret. This
module creates one `ExternalSecret` that projects named keys out of a JSON
object you store in Secrets Manager.

Unlike the GCP path, AWS has no password-less database option here, so
`DATABASE_URL` is part of that object rather than being injected by a proxy.
Put the full DSN in the JSON:

```bash
aws secretsmanager create-secret --name presponsieve/app \
  --secret-string "$(jq -n \
    --arg kek  "$(openssl rand -base64 32)" \
    --arg sess "$(openssl rand -base64 32)" \
    --arg idx  "$(openssl rand -base64 32)" \
    --arg tok  "$(openssl rand -base64 32)" \
    --arg lic  "$LICENSE_KEY" \
    --arg db   "postgresql+psycopg2://presponsieve:PASS@HOST:5432/presponsieve" \
    '{APP_KEK:$kek, SESSION_SECRET:$sess, INDEX_PEPPER:$idx,
      AUTH_TOKEN_PEPPER:$tok, LICENSE_KEY:$lic, DATABASE_URL:$db}')"
```

Back `APP_KEK` up outside this account. Losing it makes every encrypted row
unrecoverable, and no snapshot restore brings it back.

Add `OPENAI_API_KEY` to the object and to `secret_keys` to enable narrative
rendering.

## What it creates

- A versioned, encrypted S3 bucket for report artifacts, with public access
  blocked, insecure transport denied, and a 90 day lifecycle.
- An IRSA role scoped to that bucket and nothing else.
- External Secrets with its own IRSA role, reading only the one secret.
- Reloader, scoped to the namespace.

## Signed URLs

The application generates presigned S3 URLs for report downloads using the IRSA
credentials directly. No extra permission beyond `s3:GetObject` is needed, which
is simpler than the GCP path where signing goes through IAM `signBlob`.
