# aws-user-ingress

Entry point for an AWS deployment.

## What you get

- An ACM certificate for the domain, DNS-validated and auto-renewing.
- A Route 53 hosted zone, unless you bring your own.
- The AWS Load Balancer Controller with a correctly scoped IRSA role.
- A set of annotations to hand to the Helm module, which cause the controller to
  provision an ALB with TLS 1.3, HTTP-to-HTTPS redirect, IP target mode, and a
  health check against `/healthz`.

## Ordering

The ALB does not exist until the chart's Ingress resource does. That means the
DNS A record cannot be created by this module. Apply, let the release come up,
then point the record at the ALB. The `dns_instructions` output tells you how.

If you would rather this be automatic, install `external-dns` and the annotation
in `ingress_annotations` will handle it. That is a deliberate omission here
because `external-dns` needs write access to your zone, and many organisations
will not grant that to a cluster.

## Internal is usually right

`internal = false` gives you an internet-facing ALB. Faster to demo, wrong for
production. Behavioral profile data has no reason to be reachable from the
public internet. Set `internal = true` and have users arrive over VPN or Direct
Connect.

## Air-gapped note

`data "http"` fetches the load balancer controller's IAM policy from GitHub at
plan time. In an air-gapped environment this fails. Vendor the policy JSON into
the module and swap the data source for a `file()` call. See
[`guides/air-gapped.md`](../../guides/air-gapped.md).
