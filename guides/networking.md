# Networking

## Egress: what actually leaves your network

This is the table to hand a security reviewer.

| Destination | Port | When | Avoidable |
| --- | --- | --- | --- |
| PostgreSQL | 5432 | Always | No |
| Object storage | 443 | Report artifacts | No |
| Your OIDC issuer | 443 | At sign-in | Yes, use an identity-aware proxy |
| Container registry | 443 | Image pull only | Yes, mirror the image |
| `api.openai.com` | 443 | Narrative rendering and chat | **Yes, unset `OPENAI_API_KEY`** |
| Google Speech-to-Text | 443 | Audio uploads | Yes, off by default |
| kube-dns | 53 | Always | No |

There is no connection to Presponsieve at runtime. License validation is an
Ed25519 signature check against a public key in the image. Set
`LICENSE_VALIDATION_URL` if you want periodic revocation checks; leave it blank
and validation is entirely local.

## The OpenAI call, precisely

The analysis engine runs locally. Text is scored, and the simulation engine
produces reproducible percentile vectors, inside your cluster.

What OpenAI does is render those already-computed vectors into natural language:
one call per turn, plus one scenario-extraction call the first time a behaviour
scenario is set. The chat feature also requires it.

Unset `OPENAI_API_KEY` and the engine returns the same structured, deterministic
output in a templated form instead of prose. Nothing else changes, and no
request leaves your network.

If you do enable it, the call goes to OpenAI under **your** API key, on your
account, under your own agreement with them. Read `app/simulation.py` in the
application source if you want to verify the boundary rather than take this on
faith.

## Ingress

| Source | Destination | Port |
| --- | --- | --- |
| Ingress controller or load balancer | App pods | 8080 |

The Service listens on 80 and targets 8080.

## A default-deny policy

Complete and working, assuming Postgres sits in `10.20.16.0/24`. Add the OpenAI
egress rule only if you set the API key.

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: presponsieve
  namespace: presponsieve
spec:
  podSelector: {}
  policyTypes: [Ingress, Egress]

  ingress:
    - from:
        - namespaceSelector:
            matchLabels: {kubernetes.io/metadata.name: ingress-nginx}
      ports:
        - {protocol: TCP, port: 8080}

  egress:
    - to:
        - namespaceSelector:
            matchLabels: {kubernetes.io/metadata.name: kube-system}
      ports:
        - {protocol: UDP, port: 53}
    - to:
        - ipBlock: {cidr: 10.20.16.0/24}
      ports:
        - {protocol: TCP, port: 5432}
    # Object storage, and OIDC if used. Prefer private endpoints so these
    # resolve inside the VPC rather than needing a broad egress rule.
    - to:
        - ipBlock: {cidr: 0.0.0.0/0}
      ports:
        - {protocol: TCP, port: 443}
```

That last rule is broad. Narrow it to your storage and identity endpoints once
you know their addresses; the placeholder exists so the policy works on first
application rather than silently breaking report uploads.

## Identity-aware proxy: one hard requirement

With `gke.iap.enabled`, the app trusts the forwarded
`x-goog-authenticated-user-email` header and shows no login screen.

That trust is only safe if the app is reachable **only** through the proxy. Any
network path that reaches a pod directly is a path that can forge that header
and impersonate any user. Keep the namespace closed to direct traffic, and do
not expose the Service through a second ingress for convenience.

The same applies to any reverse proxy doing header-trust auth: the proxy must
strip client-supplied identity headers and re-add them from the verified
identity.

## Internal versus internet-facing

Behavioral profiles of your employees or candidates have no business being
reachable from the public internet. Where the cloud offers an internal load
balancer, use it and have users arrive over VPN or a private interconnect.

"We put SSO in front of it" is a weaker answer to a reviewer than "it is not
routable from outside our network."

## Request size and timeouts

Transcripts and audio go well past the nginx 1MB body default, and an analysis
can hold a connection for minutes. Every example sets these; if you write your
own ingress, do not omit them.

```yaml
nginx.ingress.kubernetes.io/proxy-body-size: "100m"
nginx.ingress.kubernetes.io/proxy-read-timeout: "600"
nginx.ingress.kubernetes.io/proxy-send-timeout: "600"
```

On GKE the equivalent is a `BackendConfig` with `timeoutSec: 600`. The GCLB
default is 30 seconds, shorter than a long analysis, and past it the load
balancer returns an HTML 502 the app never sees. The Helm module renders this
automatically when IAP is enabled.
