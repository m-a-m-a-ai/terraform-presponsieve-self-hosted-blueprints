# aws-vpc

Network foundation for an AWS deployment of Presponsieve.

Three-AZ VPC with public subnets for load balancers only, large private subnets
for EKS nodes and RDS, one NAT gateway per AZ, and interface endpoints for the
AWS services the deployment actually uses.

## Subnet sizing

Private subnets are `/18` and public are `/20`. The asymmetry is intentional.
Under the VPC CNI every pod consumes a real subnet address, so the private
ranges have to absorb pod count, not just node count. Public subnets only ever
hold load balancer ENIs.

## Interface endpoints

Secrets Manager, KMS, ECR, CloudWatch Logs, and STS are reached over PrivateLink
rather than NAT. Two reasons: NAT data processing charges disappear for the
majority of your egress, and a security reviewer sees no path from the workload
subnets to the internet for secret material.

S3 uses a gateway endpoint, which is free.

## Cost

Three NAT gateways is the production answer and roughly triples the fixed
network cost versus one. Set `single_nat_gateway = true` for non-production
environments only. A zone failure then takes all private egress with it.
