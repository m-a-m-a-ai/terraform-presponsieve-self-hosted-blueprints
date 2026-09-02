# aws-database

Private RDS for Postgres instance backing Presponsieve.

## What you get

- No public accessibility. Reachable only from the security groups you name in
  `allowed_security_group_ids`.
- `rds.force_ssl = 1`. Plaintext connections are refused at the server, not just
  discouraged by the client.
- `pgvector` preloaded, which Presponsieve needs for trait embeddings.
- Storage autoscaling from 100GB to 1TB.
- Multi-AZ with a synchronous standby.
- 30 days of automated backups, Performance Insights, enhanced monitoring, and
  Postgres logs shipped to CloudWatch.
- A generated password written to Secrets Manager under a customer-managed KMS
  key.

## Password handling

Terraform generates the password, so it exists in state. Unavoidable when
Terraform creates the master user. Use an encrypted remote backend with tight
access control.

`ignore_changes = [password]` is set on the instance. This means rotating
through Secrets Manager rotation or the console will not cause Terraform to
revert it on the next apply.

## Both destroy guards are on

`deletion_protection` and `prevent_destroy` both block removal, and
`skip_final_snapshot` is false. Removing this database is a deliberate,
multi-step act by design.
