# Licensing

Presponsieve is commercial software. Running it requires a license key,
purchased separately.

## How the gate works

The license is an Ed25519-signed token. `LICENSE_PUBLIC_KEY` in the chart's
config holds the base64 public key that verifies it. Both the token and the
public key come from your dashboard at presponsieve.ai/dashboard, reached by a
single-use sign-in link sent to the email the license was issued against.
Verification is a local signature check.

`LICENSE_ENFORCEMENT` selects the behaviour:

| Value | Effect |
| --- | --- |
| `enforce` | Default. An invalid or missing license blocks the engine |
| `warn` | Logs and continues. For a migration window, not for production |
| `disabled` | No gate. Development only |

Leaving `LICENSE_PUBLIC_KEY` blank also disables the gate entirely.

## The content key

The model assets baked into the image are encrypted. Decrypting them requires
`MODEL_CONTENT_KEY`, and without it the engine has no model to run.

A license token can carry the content key itself, in which case
`MODEL_CONTENT_KEY` can be left blank and `LICENSE_KEY` alone unlocks the
engine. That is the normal path.

This is a stronger mechanism than a license check, because there is nothing to
patch out. An unlicensed copy of the image is missing the material it needs to
function.

## Revocation

`LICENSE_VALIDATION_URL` is optional. Set it to
`https://presponsieve.ai/validate` and the app polls every
`LICENSE_REFRESH_INTERVAL_HOURS`, default 12, to learn whether the license has
been revoked. Leave it blank and validation is entirely offline, with no egress
at any point.

Revocation is learned on the next poll, lives in pod memory, and is cleared by
a restart until the poll after that. Only expiry survives a restart. It is a
commercial lever, not a kill switch.

Offline is the default. Consider revocation checks only if your commercial terms
need them, and be aware they introduce a runtime dependency that offline
validation does not have.

## Installing the key

`LICENSE_KEY` is one entry in the single application secret. Do not put it in a
values file or a `.tf` file.

Each cloud services module syncs the whole secret from your cloud secret
manager, so the key reaches the cluster without touching Terraform state. See
the module READMEs for the exact commands.

## Renewal

Renewal is a secret update, not a redeployment.

1. Add a new version to the cloud secret with the new `LICENSE_KEY`.
2. External Secrets picks it up within `secret_refresh_interval`, one hour by
   default.
3. Reloader sees the Kubernetes secret change and triggers a rolling restart.

No new image, no chart change, no downtime beyond the restart. To force an
immediate sync:

```bash
kubectl annotate externalsecret presponsieve-secrets -n presponsieve \
  force-sync="$(date +%s)" --overwrite
```

Renew early. There is no reason to wait, and it converts a deadline into a
chore.
