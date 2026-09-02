# gcp-vpc

Network foundation for a GCP deployment of Presponsieve.

Creates a custom-mode VPC with one regional subnet, secondary ranges for GKE
pods and services, Cloud NAT for private node egress, and the reserved peering
range Cloud SQL requires for a private IP instance.

## Sizing the secondary ranges

The pod range must hold `max_nodes * 110` addresses. The `/14` default supports
roughly 2,300 nodes, which is far more than any Presponsieve deployment needs
but costs nothing and cannot be resized later. Shrink it only if it collides
with an existing range in your organisation.

## Egress

Cloud NAT exists so private nodes can pull images and reach your OIDC provider.
Presponsieve itself never calls home. If you mirror images internally and use an
in-VPC identity provider, delete the router and NAT resources and the deployment
still functions. See [`guides/air-gapped.md`](../../guides/air-gapped.md).
