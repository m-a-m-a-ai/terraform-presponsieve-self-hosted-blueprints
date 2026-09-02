# Azure, all inclusive

Takes an empty Azure subscription to a running Presponsieve deployment.
Provisions the VNet, an AKS cluster with workload identity, a private Postgres
Flexible Server, a Key Vault, an Application Gateway with WAF, and the Helm
release.

## Before you start

Register the resource providers:

```bash
az provider register --namespace Microsoft.ContainerService
az provider register --namespace Microsoft.DBforPostgreSQL
az provider register --namespace Microsoft.KeyVault
az provider register --namespace Microsoft.Network
```

Import a TLS certificate. Azure does not offer a free managed certificate for
Application Gateway, so you must supply one:

```bash
az keyvault certificate import --vault-name presponsieve-kv \
  --name presponsieve-tls --file cert.pfx
```

That vault is created by this example, which means the certificate import
happens after the first apply. Plan for two passes, or point
`key_vault_id` at an existing vault you already control.

## Deploy

```bash
cp provider.example.tf provider.tf
# edit the locals block at the top of main.tf
terraform init
terraform plan
terraform apply
```

Expect 30 to 40 minutes. The Application Gateway alone takes 15.

## Known ordering quirks

**Key Vault RBAC propagation.** The module grants the deploying principal
`Key Vault Secrets Officer` and then immediately writes secrets. Azure RBAC is
eventually consistent, so a first apply sometimes fails on the first secret
write. Re-run `terraform apply`. It succeeds on the second attempt.

**Private access is permanent.** A Postgres Flexible Server cannot move between
private and public access after creation. Get it right the first time.

**Local accounts are disabled** on the cluster, so `az aks get-credentials`
returns an Entra ID kubeconfig. Grant yourself
`Azure Kubernetes Service RBAC Cluster Admin` at the cluster scope before you
try to use it.

## Costs

Rough monthly figures at defaults, East US 2, pay-as-you-go:

| Component | Approximate |
| --- | --- |
| AKS Standard tier control plane | $73 |
| 3 x Standard_D4s_v5 nodes | $420 |
| Postgres GP_Standard_D2ds_v5, zone-redundant HA | $390 |
| Application Gateway WAF_v2, 2 instances | $260 |
| Key Vault, storage, egress | $40 |
| **Total** | **≈ $1,180** |

Application Gateway on WAF_v2 is the most expensive component relative to what
it does. Reserved Instances on the nodes and database will take roughly 30 per
cent off the compute lines.

## One WAF rule is disabled

The OWASP SQL injection rule group is off. Presponsieve accepts arbitrary prose
for analysis and that ruleset produces constant false positives against it. The
reasoning is in [`modules/azure-user-ingress`](../../modules/azure-user-ingress).
Record it in your risk register.
