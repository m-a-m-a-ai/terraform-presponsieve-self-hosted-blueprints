# AWS, all inclusive

Takes an empty AWS account to a running Presponsieve deployment. Provisions the
VPC with interface endpoints, an EKS cluster, a Multi-AZ RDS Postgres instance,
Secrets Manager wiring, an ALB with an ACM certificate, and the Helm release.

## Before you start

Store your license key. This is the path that keeps it out of Terraform state:

```bash
aws secretsmanager create-secret \
  --name presponsieve/license \
  --secret-string "$LICENSE_KEY"
```

Confirm your credentials can create IAM roles, VPCs, EKS clusters, and RDS
instances. A permissions boundary that blocks `iam:CreateRole` is the most
common first failure.

## Deploy

```bash
cp provider.example.tf provider.tf
# edit the locals block at the top of main.tf
terraform init
terraform plan
terraform apply
```

Expect 25 to 35 minutes. EKS and RDS dominate that.

## Two-stage apply

The Kubernetes and Helm providers read from the EKS module's outputs, which do
not exist on the first plan. If you hit `Invalid provider configuration` on a
clean run:

```bash
terraform apply -target=module.vpc -target=module.eks -target=module.database
terraform apply
```

## After apply

1. Take the `name_servers` output and delegate the zone at your registrar. ACM
   cannot validate the certificate until you do, and `apply` will sit waiting.
2. Once the release is up, find the ALB and create the ALIAS record:

   ```bash
   kubectl get ingress -n presponsieve
   ```

   The `ADDRESS` column is your ALB hostname. Create an ALIAS A record for
   `presponsieve.acme.com` pointing at it.

3. Open `https://presponsieve.acme.com`.

## Costs

Rough monthly figures at defaults, us-east-1, on-demand:

| Component | Approximate |
| --- | --- |
| EKS control plane | $73 |
| 3 x m6i.xlarge nodes | $420 |
| RDS db.m6g.large Multi-AZ | $370 |
| 3 x NAT gateway | $100 |
| ALB, interface endpoints, storage | $90 |
| **Total** | **≈ $1,050** |

Savings Plans on the nodes and a Reserved Instance on RDS take a meaningful bite
out of that. For non-production, set `single_nat_gateway = true` and
`multi_az = false` to save roughly $250.

## Cleaning up

The RDS instance carries both `deletion_protection` and `prevent_destroy`, and
`skip_final_snapshot` is false. `terraform destroy` will fail until you change
those deliberately. That is the intent.
