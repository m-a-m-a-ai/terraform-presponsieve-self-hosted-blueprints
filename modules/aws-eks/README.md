# aws-eks

EKS cluster sized for Presponsieve, with a managed node group.

## What you get

- Private-subnet control plane ENIs and nodes.
- The public API endpoint is disabled unless you populate
  `public_access_cidrs`. Empty is the default.
- Envelope encryption of Kubernetes secrets using a rotating customer-managed
  KMS key.
- An IAM OIDC provider, so pods assume roles through IRSA rather than sharing
  the node role.
- API-mode access entries. `aws-auth` ConfigMap editing is not required.
- Control plane audit logging to CloudWatch.
- EBS CSI driver with its own IRSA role. The chart provisions a PVC for the
  model cache, so this is not optional.

## Reaching the API server

With `public_access_cidrs` empty the endpoint is private only. You will need a
bastion, VPN, or SSM session inside the VPC to run `kubectl`. That is the
correct posture for production. For a first deployment from a laptop:

```hcl
public_access_cidrs = ["203.0.113.42/32"]
```

Narrow it to a single address, not `0.0.0.0/0`.

## Node sizing

Worker pods request 4Gi of memory and hold analysis models resident.
`m6i.xlarge` fits one worker plus system overhead. Scaling `worker_replicas` in
the Helm module without raising `node_max_size` here will leave pods pending.
