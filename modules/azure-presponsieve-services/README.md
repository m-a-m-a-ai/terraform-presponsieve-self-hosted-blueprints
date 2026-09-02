# azure-presponsieve-services

Identity, secrets, and storage for an AKS deployment.

> Azure is the generic path. The chart ships tested overlays for GKE and EKS
> only; Azure follows the same external-database, external-storage, external-OIDC
> shape as the AWS overlay. Treat these modules as a working starting point
> rather than a reference deployment.

## The one secret

The chart reads every sensitive value from a single Kubernetes secret. This
module projects Key Vault secrets into it.

Key Vault secret names cannot contain underscores, so store them hyphenated and
the module maps them back:

```bash
VAULT=presponsieve-kv
az keyvault secret set --vault-name $VAULT --name APP-KEK           --value "$(openssl rand -base64 32)"
az keyvault secret set --vault-name $VAULT --name SESSION-SECRET    --value "$(openssl rand -base64 32)"
az keyvault secret set --vault-name $VAULT --name INDEX-PEPPER      --value "$(openssl rand -base64 32)"
az keyvault secret set --vault-name $VAULT --name AUTH-TOKEN-PEPPER --value "$(openssl rand -base64 32)"
az keyvault secret set --vault-name $VAULT --name LICENSE-KEY       --value "$LICENSE_KEY"
az keyvault secret set --vault-name $VAULT --name DATABASE-URL      --value "postgresql+psycopg2://..."
```

Back `APP-KEK` up outside this subscription. Losing it makes every encrypted row
unrecoverable.

## RBAC propagation

The module grants the deploying principal `Key Vault Secrets Officer` and then
uses the vault. Azure RBAC is eventually consistent, so a first apply
occasionally fails on the first vault operation. Re-run it.
