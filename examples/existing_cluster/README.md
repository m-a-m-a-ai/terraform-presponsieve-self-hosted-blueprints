# Existing cluster

Deploys Presponsieve into a cluster your platform team already runs. No
cloud infrastructure is provisioned.

## What you need first

| Requirement | Detail |
| --- | --- |
| Kubernetes | 1.27 or later |
| Postgres | 14 or later, reachable from the cluster |
| Object storage | An S3-compatible bucket, or GCS |
| Ingress | Any conformant controller |
| TLS | A secret in the namespace, or cert-manager |
| Identity | An OIDC issuer, or an identity-aware proxy in front |

## Prepare the database

The migration Job creates the schema, but not the database or the role.

```sql
CREATE ROLE presponsieve WITH LOGIN PASSWORD '...';
CREATE DATABASE presponsieve OWNER presponsieve;
```

## Create the application secret

Everything sensitive lives in one secret. Generate the crypto material and keep
it somewhere other than the cluster.

```bash
kubectl create namespace presponsieve

kubectl create secret generic presponsieve-secrets -n presponsieve \
  --from-literal=APP_KEK="$(openssl rand -base64 32)" \
  --from-literal=SESSION_SECRET="$(openssl rand -base64 32)" \
  --from-literal=INDEX_PEPPER="$(openssl rand -base64 32)" \
  --from-literal=AUTH_TOKEN_PEPPER="$(openssl rand -base64 32)" \
  --from-literal=LICENSE_KEY="$LICENSE_KEY" \
  --from-literal=DATABASE_URL="postgresql+psycopg2://presponsieve:PASS@db.internal:5432/presponsieve"
```

Add `--from-literal=OPENAI_API_KEY=sk-...` to enable narrative rendering and
chat. Without it the engine still returns structured, deterministic output.

For production use External Secrets, Vault, or Sealed Secrets rather than
`kubectl create secret`. The chart only needs the secret to exist with these
keys.

> **`APP_KEK` is not recoverable.** Losing it makes every encrypted row
> permanently unreadable. Back it up somewhere that survives the cluster, the
> namespace, and the person who created it.

## Deploy

```bash
cp provider.example.tf provider.tf
kubectl config current-context   # confirm you are pointed at the right cluster
terraform init
terraform apply
```

## Verify

A health check only proves the pod started. Run one analysis end to end: it
exercises the database write, the object storage upload, and signed-URL
retrieval in a single flow.

```bash
kubectl get pods,job -n presponsieve
kubectl port-forward -n presponsieve svc/presponsieve 8080:80
curl -s localhost:8080/healthz    # {"status":"ok"}
```

Then sign in, run an analysis, and confirm the report, radar image, and PDF all
come back.

## Network policy

If your cluster enforces default-deny, the application needs DNS, Postgres,
your object storage endpoint, and your OIDC issuer. It also needs
`api.openai.com` **only if** you set `OPENAI_API_KEY`. See
[`guides/networking.md`](../../guides/networking.md).

## Sizing

The workload is one stateless Deployment. Two replicas is a sensible floor, and
`SESSION_SECRET` must be set for more than one, or an SSO callback landing on a
different pod than the one that started the flow will fail.
