data "azurerm_client_config" "current" {}

locals {
  # Key Vault secret names cannot contain underscores, so the environment
  # variable names are hyphenated in the vault and mapped back on the way in.
  secret_map = { for k in var.secret_keys : replace(k, "-", "_") => k }
}

# ---------------------------------------------------------------------------
# Key Vault. RBAC authorization rather than access policies: access policies are
# per-vault, invisible to Azure Policy, and cannot be reasoned about from the
# subscription level.
# ---------------------------------------------------------------------------

resource "azurerm_key_vault" "this" {
  name                = "${var.prefix}-kv"
  resource_group_name = var.resource_group_name
  location            = var.location
  tenant_id           = var.tenant_id
  sku_name            = "standard"
  tags                = var.tags

  rbac_authorization_enabled    = true
  purge_protection_enabled      = true
  soft_delete_retention_days    = 90
  public_network_access_enabled = false

  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
  }
}

resource "azurerm_role_assignment" "deployer" {
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}

# ---------------------------------------------------------------------------
# Workload identity
# ---------------------------------------------------------------------------

resource "azurerm_user_assigned_identity" "app" {
  name                = "${var.prefix}-app"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}

resource "azurerm_federated_identity_credential" "app" {
  name                      = "${var.prefix}-app"
  user_assigned_identity_id = azurerm_user_assigned_identity.app.id
  audience                  = ["api://AzureADTokenExchange"]
  issuer                    = var.oidc_issuer_url
  subject                   = "system:serviceaccount:${var.namespace}:${var.service_account_name}"
}

resource "azurerm_role_assignment" "app_secrets" {
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.app.principal_id
}

resource "kubernetes_service_account_v1" "app" {
  metadata {
    name      = var.service_account_name
    namespace = var.namespace

    annotations = {
      "azure.workload.identity/client-id" = azurerm_user_assigned_identity.app.client_id
      "azure.workload.identity/tenant-id" = var.tenant_id
    }

    labels = {
      "azure.workload.identity/use" = "true"
    }
  }
}

# ---------------------------------------------------------------------------
# Report artifact storage, exposed over the S3-compatible path.
# ---------------------------------------------------------------------------

resource "azurerm_storage_account" "artifacts" {
  name                     = replace("${var.prefix}artifacts", "-", "")
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "ZRS"
  tags                     = var.tags

  min_tls_version                 = "TLS1_2"
  https_traffic_only_enabled      = true
  allow_nested_items_to_be_public = false

  blob_properties {
    versioning_enabled = true

    delete_retention_policy {
      days = 30
    }
  }
}

resource "azurerm_storage_container" "artifacts" {
  name                  = "artifacts"
  storage_account_id    = azurerm_storage_account.artifacts.id
  container_access_type = "private"
}

resource "azurerm_role_assignment" "app_storage" {
  scope                = azurerm_storage_account.artifacts.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.app.principal_id
}
