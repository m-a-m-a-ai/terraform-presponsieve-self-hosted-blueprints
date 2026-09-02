# Upgrades

## Pin your versions

Both `chart_version` and `image_tag` default to null, which resolves to whatever
is newest at apply time. Two applies a week apart would then install different
software with nothing in your Terraform to explain it.

```hcl
chart_version = "0.1.0"
image_tag     = "0.1.0"
```

Moving those strings is the upgrade. It shows up in review, in history, and in
`terraform plan`.

## Before you upgrade

**Back up the database.** The migration Job runs `alembic upgrade head` as a
pre-install and pre-upgrade hook. Migrations are forward-only, and Helm does not
roll them back.

**Check your `extra_values`.** Anything there is unvalidated by the module. A
chart that renames a value silently ignores your old key, and the feature you
configured quietly stops being configured.

## Running it

```bash
# Snapshot first
gcloud sql backups create --instance presponsieve-pg
aws rds create-db-snapshot --db-instance-identifier presponsieve-pg \
  --db-snapshot-identifier presponsieve-pre-upgrade

# Then move the pins and apply
terraform plan
terraform apply
```

The module sets `atomic = true`, so a release that fails to become ready within
`timeout` rolls back rather than leaving the cluster half-upgraded.

The migration is the exception, which is why the snapshot matters. An
unreachable database fails the install cleanly, before any pod starts against a
schema that is not there.

## Rolling back

If the release itself failed:

```bash
helm rollback presponsieve -n presponsieve
```

Then move the pins back in Terraform so code matches reality. A `helm rollback`
not reflected in Terraform is undone by the next `terraform apply`, usually at
the worst possible moment.

**A rollback reverts pods, not the schema.** If the migration succeeded and the
application is misbehaving, rolling the chart back is not enough. Restore the
snapshot.

## The encryption backfill

`run_backfill = true` enables a one-off Job that encrypts pre-existing plaintext
rows. It is idempotent. Enable it once after provisioning a KEK, confirm it
completed, then set it back to false so it does not run on every upgrade.

## Kubernetes upgrades

The chart supports 1.27 and later. The Cloud SQL Auth Proxy sidecar needs 1.29,
because it runs as a native sidecar.

Move the cluster version in a separate apply from the chart version. Cluster
upgrades take 30 to 60 minutes and roll every node.
