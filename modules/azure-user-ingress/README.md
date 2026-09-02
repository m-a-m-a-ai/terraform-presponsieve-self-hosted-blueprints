# azure-user-ingress

Entry point for an Azure deployment.

## What you get

- A zone-redundant Application Gateway on the WAF_v2 SKU, autoscaling from 2 to
  10 instances, with OWASP 3.2 in prevention mode.
- The Application Gateway Ingress Controller enabled as an AKS cluster
  extension. From that point the chart's Ingress resource drives the gateway.
- A public DNS zone and A record, unless the deployment is internal or you bring
  your own zone.
- TLS 1.2 minimum through the `AppGwSslPolicy20220101S` predefined policy.

## You must supply a certificate

Azure does not offer free managed certificates for Application Gateway. Import
one into Key Vault, then set `certificate_secret_name` and `key_vault_id`. The
gateway's managed identity is granted read access automatically.

```bash
az keyvault certificate import --vault-name <vault> \
  --name presponsieve-tls --file cert.pfx
```

Without this the gateway serves HTTP only, which is acceptable for a sandbox
and nothing else.

## One WAF rule is disabled

`REQUEST-942-APPLICATION-ATTACK-SQLI` is off. Presponsieve accepts arbitrary
free text for analysis, and ordinary prose reliably trips the SQL injection
ruleset. Leaving it on causes legitimate submissions to return 403.

This is a deliberate, scoped exception. Presponsieve parameterises every query,
so SQL injection is mitigated at the application layer rather than by the WAF.
Note it in your risk register rather than discovering it during a pen test.

## The placeholder configuration is expected

The gateway is created with a placeholder listener, backend pool, and rule.
Azure will not create a gateway without them. AGIC replaces all of it on first
reconcile, and the `ignore_changes` block stops Terraform from fighting the
controller afterwards.
