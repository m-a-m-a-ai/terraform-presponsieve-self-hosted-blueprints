# azure-aks

AKS cluster sized for Presponsieve.

## What you get

- Azure CNI in overlay mode with Cilium as both network policy engine and data
  plane. Pods draw from a separate CIDR, so the node subnet does not have to
  absorb pod count.
- Workload identity federation and an OIDC issuer. Pods obtain Entra tokens
  without any stored secret.
- Entra ID integration with Azure RBAC, and `local_account_disabled = true`.
  This matters: local accounts issue non-expiring cluster-admin credentials that
  bypass your identity provider entirely.
- API server access restricted to `authorized_ip_ranges`, which is empty by
  default.
- Key Vault CSI provider with five-minute secret rotation.
- Zone-spread autoscaling node pool with a weekly maintenance window.

## Before you run kubectl

`authorized_ip_ranges` is empty, so the API server is closed. Add your VPN
egress range:

```hcl
authorized_ip_ranges = ["203.0.113.0/24"]
```

Because local accounts are disabled, `az aks get-credentials` returns an Entra
ID kubeconfig. You will be prompted to authenticate, and your Entra principal
needs an Azure RBAC role on the cluster. Grant yourself
`Azure Kubernetes Service RBAC Cluster Admin` at the cluster scope.

## Node sizing

Worker pods request 4Gi and hold analysis models resident. `Standard_D4s_v5`
fits one worker plus system overhead. Raise `node_max_count` alongside
`worker_replicas`.
