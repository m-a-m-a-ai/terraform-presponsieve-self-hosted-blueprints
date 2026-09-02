# gcp-database

Private Cloud SQL for Postgres instance with IAM database authentication.

## No password exists

This module generates no password, creates no Secret Manager entry, and writes
no credential to Terraform state. The workload connects through the Cloud SQL
Auth Proxy sidecar using the pod's Workload Identity, and Cloud SQL
authenticates that identity directly.

There is no database credential to rotate, leak, or forget to rotate. That is
the entire reason this path is the default on GCP.

## What you get

- No public IP. Reachable only over the VPC peering the network module set up.
- TLS required at the server.
- `cloudsql.iam_authentication` on, which is what makes the IAM user work.
- Regional high availability with a synchronous standby.
- Point-in-time recovery with seven days of transaction logs and 30 retained
  backups.
- `prevent_destroy` plus provider-level deletion protection.

## Ordering

`app_service_account_email` comes from the services module, which must apply
first. The IAM user cannot be created before the service account exists.

## Connecting

Pass two outputs to the Helm module:

```hcl
cloud_sql_proxy = {
  instance_connection_name = module.database.connection_name
  iam_user                 = module.database.iam_user
  database_name            = module.database.database_name
}
```

The chart then injects `DATABASE_URL` pointing at the proxy's local listener.

Requires Kubernetes 1.29 or later, because the proxy runs as a native sidecar.
On an older cluster, fall back to a password and `database_url` on the Helm
module, and accept that the credential now exists somewhere.
