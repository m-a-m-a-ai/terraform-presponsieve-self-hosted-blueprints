# gcp-user-ingress

Reserved address and DNS for a GKE deployment.

## What this module does not do

It does not create an Ingress, a certificate, or a BackendConfig. The chart
renders all three. This module provisions only the two things that must exist
before the chart runs and must outlive it: a reserved global address, and the
DNS record pointing at it.

That split matters. If Terraform created the Ingress, it would fight the chart
on every upgrade.

## The certificate

The chart renders a `ManagedCertificate` named `<fullname>-cert`. The Helm
module pins `fullnameOverride` to `presponsieve`, so that is
`presponsieve-cert`, and the `ingress_annotations` output already references
it. Change one and you must change the other.

Issuance blocks on DNS validation. If this module created the zone, delegate the
name servers at your registrar first. The certificate stays pending until you
do, typically 15 minutes and occasionally an hour.

```bash
kubectl get managedcertificate -n presponsieve
```

## IAP

Identity-Aware Proxy is the recommended sign-in path on GKE: Google
authenticates every request before it reaches the app.

The OAuth client has to be created by hand in the console, then stored as a
Kubernetes secret with `client_id` and `client_secret` keys. Pass the secret
name to the Helm module as `gke_iap.oauth_client_secret_name`.

IAP is only safe when the app is reachable **only** through the load balancer.
The app trusts the forwarded `x-goog-authenticated-user-email` header, so any
path that reaches a pod directly is a path that can forge identity. Keep the
namespace closed to direct traffic.
