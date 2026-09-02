# Changelog

Notable changes to these blueprints. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/). Versions track the
blueprints, not the application.

## [Unreleased]

### Added

- Module set for GCP, AWS, and Azure.
- Cloud-agnostic `presponsieve-helm` module wrapping the published chart at
  `oci://ghcr.io/m-a-m-a-ai/charts/presponsievelite`.
- `existing_cluster` example for platform-team-owned clusters.
- GCP path uses Cloud SQL IAM database authentication through the Auth Proxy
  sidecar, so no database password exists anywhere in the deployment.
- Single-secret contract matching the chart's `app.existingSecret`, synced from
  each cloud's secret manager through External Secrets.

### Provider constraints

- Helm provider `>= 3.0.2`. Version 3.0 moved to the Terraform plugin
  framework, turning `set` into a list of nested objects and the provider's
  `kubernetes` block into a nested attribute. Configurations written against
  2.x will not parse. 3.0.2 is the floor because it fixed plan inconsistencies
  in 3.0.0 and 3.0.1.
- Kubernetes resources use the `_v1` suffixed names.
- `data.aws_region.current.region` replaces the deprecated `.name`.
- `azurerm_kubernetes_cluster` requires a `node_provisioning_profile` block.
  Set to `Manual`, so AKS does not auto-provision node pools alongside the
  explicit autoscaling pool.
