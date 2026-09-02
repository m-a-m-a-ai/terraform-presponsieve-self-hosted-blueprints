# GKE, all inclusive

Takes an empty GCP project to a running Presponsieve deployment. This is
the Terraform equivalent of the chart's `values-gke.example.yaml`.

## What it builds

- VPC with private nodes and Cloud NAT.
- Regional private GKE cluster with Workload Identity.
- Cloud SQL for Postgres with **IAM database authentication and no password**.
- A GCS bucket for report artifacts, reachable through Workload Identity.
- One service account holding every permission the workload needs.
- External Secrets syncing the application secrets from Secret Manager.
- A reserved global address and DNS record.
- The Helm release, with the Cloud SQL Auth Proxy sidecar and IAP.

## Before you start

Enable the APIs:

```bash
gcloud services enable \
  compute.googleapis.com container.googleapis.com sqladmin.googleapis.com \
  servicenetworking.googleapis.com secretmanager.googleapis.com \
  iap.googleapis.com dns.googleapis.com \
  --project acme-presponsieve
```

Create the application secret. Nothing sensitive should reach Terraform:

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

**Back `APP_KEK` up outside this project.** Losing it makes every encrypted row
unrecoverable. No database restore brings it back.

Create the IAP OAuth client in the console, then store it in the cluster:

```bash
kubectl create namespace presponsieve
kubectl create secret generic presponsieve-iap-oauth -n presponsieve \
  --from-literal=client_id="$IAP_CLIENT_ID" \
  --from-literal=client_secret="$IAP_CLIENT_SECRET"
```

## Deploy

```bash
cp provider.example.tf provider.tf
# edit the locals block at the top of main.tf
terraform init
terraform plan
terraform apply
```

Expect 20 to 30 minutes.

## Two-stage apply

The Kubernetes and Helm providers read from GKE module outputs that do not
exist during the first plan. If you hit `Invalid provider configuration`:

```bash
terraform apply -target=module.vpc -target=module.gke
terraform apply
```

## After apply

Delegate the zone using the `name_servers` output. The Google-managed
certificate cannot be issued until delegation is live:

```bash
kubectl get managedcertificate -n presponsieve
```

Then open `https://app.acme.com`. IAP will authenticate you with Google before
the request reaches the app.

## Verify properly

A health check proves the pod started. Run one analysis end to end instead: it
exercises the database write, the GCS upload, and signed-URL retrieval in a
single flow.

```bash
kubectl get pods,job -n presponsieve
kubectl port-forward -n presponsieve svc/presponsieve 8080:80
curl -s localhost:8080/healthz
```

Then sign in and confirm the report, radar image, and PDF all come back. If the
PDF download fails while everything else works, the signBlob binding is missing.

## Requirements worth checking

The Cloud SQL Auth Proxy runs as a **native sidecar**, which needs Kubernetes
1.29 or later. The GKE module targets a recent stable channel, so this is
normally satisfied, but confirm before assuming.

## Approximate cost

At defaults, us-central1, list price:

| Component | Monthly |
| --- | --- |
| GKE regional cluster fee | $73 |
| 3 x n2-standard-4 | $290 |
| Cloud SQL db-custom-2-7680, regional HA | $360 |
| Load balancer, NAT, egress | $60 |
| **Total** | **≈ $780** |

Committed use discounts cut the compute lines substantially. For non-production,
`availability_type = "ZONAL"` on the database saves around $180.

## Cleaning up

The database carries `prevent_destroy` and provider deletion protection.
`terraform destroy` fails until you remove both deliberately.
