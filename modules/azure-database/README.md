# azure-database

Private Postgres Flexible Server backing Presponsieve.

## What you get

- `public_network_access_enabled = false`. The server has no public endpoint at
  all, not merely a firewall in front of one.
- VNet-integrated through the delegated subnet, resolvable through the private
  DNS zone the network module created.
- `require_secure_transport = ON`. Plaintext connections are refused at the
  server.
- `pgvector` allowlisted, which Presponsieve needs for trait embeddings.
- Zone-redundant high availability with a standby in zone 2.
- 35 days of backups, which is Azure's maximum.
- A generated password written to Key Vault.

## Extensions are allowlisted, not installed

Setting `azure.extensions` permits the extension. Presponsieve's migration then
runs `CREATE EXTENSION vector`. If you tighten this list and drop `VECTOR`, the
first migration after an upgrade will fail.

## Private access is permanent

Azure does not allow a Flexible Server to move between private access and public
access after creation. If you get this wrong, the fix is a new server and a
restore. Decide before the first apply.

## Destroy guards

`prevent_destroy` is set on both the server and the database. Removing them is a
deliberate two-step act, which is the intent.
