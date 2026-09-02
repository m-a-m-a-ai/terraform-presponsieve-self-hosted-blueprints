# gcp-gke

Regional, private GKE cluster sized for Presponsieve.

## What you get

- Private nodes. The control plane endpoint stays public but is closed to
  everything except `master_authorized_networks`, which defaults to empty.
- Workload Identity, so pods authenticate to GCP without service account keys.
- Envelope encryption of etcd secrets using a customer-managed KMS key that
  rotates every 90 days.
- Calico network policy enforcement.
- Gateway API on the standard channel. The `gcp-user-ingress` module uses it.
- Managed Prometheus for metrics.

## Before you run kubectl

`master_authorized_networks` is empty by default, which means your laptop
cannot reach the control plane. This is deliberate. Add your VPN egress range
or bastion address:

```hcl
master_authorized_networks = [{
  cidr_block   = "203.0.113.0/24"
  display_name = "corp-vpn"
}]
```

## Deletion protection

`deletion_protection` is on. A `terraform destroy` will fail until you set it to
false and apply that change first. Removing this guard from the module is not
recommended.

## Node sizing

Worker pods request 4Gi of memory because the analysis models are held resident.
`n2-standard-4` fits one worker plus system overhead per node. If you raise
`worker_replicas`, raise `node_max_count` with it.
