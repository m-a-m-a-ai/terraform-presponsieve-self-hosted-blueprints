resource "azurerm_user_assigned_identity" "cluster" {
  name                = "${var.prefix}-aks"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}

resource "azurerm_role_assignment" "network" {
  scope                = var.nodes_subnet_id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_user_assigned_identity.cluster.principal_id
}

resource "azurerm_kubernetes_cluster" "this" {
  name                = "${var.prefix}-aks"
  resource_group_name = var.resource_group_name
  location            = var.location
  dns_prefix          = var.prefix
  kubernetes_version  = var.kubernetes_version
  sku_tier            = "Standard"
  tags                = var.tags

  # Local accounts issue non-expiring cluster-admin credentials that bypass
  # Entra ID entirely. Off.
  local_account_disabled            = true
  role_based_access_control_enabled = true

  azure_active_directory_role_based_access_control {
    azure_rbac_enabled     = true
    tenant_id              = var.tenant_id
    admin_group_object_ids = var.admin_group_object_ids
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.cluster.id]
  }

  # Workload identity federation. Pods get Entra tokens without secrets.
  workload_identity_enabled = true
  oidc_issuer_enabled       = true

  api_server_access_profile {
    authorized_ip_ranges = var.authorized_ip_ranges
  }

  # Required by azurerm 4.x. Manual means AKS does not auto-provision node
  # pools behind our backs; the explicit autoscaling pool below is the only
  # source of nodes.
  node_provisioning_profile {
    mode = "Manual"
  }

  default_node_pool {
    name                 = "general"
    vm_size              = var.node_vm_size
    vnet_subnet_id       = var.nodes_subnet_id
    zones                = var.availability_zones
    auto_scaling_enabled = true
    min_count            = var.node_min_count
    max_count            = var.node_max_count
    os_disk_size_gb      = 100
    os_disk_type         = "Managed"
    max_pods             = 60
    type                 = "VirtualMachineScaleSets"
    upgrade_settings {
      max_surge = "25%"
    }
  }

  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    network_policy      = "cilium"
    network_data_plane  = "cilium"
    load_balancer_sku   = "standard"
    outbound_type       = "loadBalancer"
    pod_cidr            = "10.244.0.0/16"
    service_cidr        = "10.0.0.0/16"
    dns_service_ip      = "10.0.0.10"
  }

  key_vault_secrets_provider {
    secret_rotation_enabled  = true
    secret_rotation_interval = "5m"
  }

  storage_profile {
    disk_driver_enabled = true
    file_driver_enabled = true
  }

  dynamic "oms_agent" {
    for_each = var.log_analytics_workspace_id != null ? [1] : []
    content {
      log_analytics_workspace_id      = var.log_analytics_workspace_id
      msi_auth_for_monitoring_enabled = true
    }
  }

  auto_scaler_profile {
    balance_similar_node_groups = true
    expander                    = "least-waste"
  }

  maintenance_window_auto_upgrade {
    frequency   = "Weekly"
    interval    = 1
    duration    = 4
    day_of_week = "Sunday"
    start_time  = "04:00"
    utc_offset  = "+00:00"
  }

  lifecycle {
    ignore_changes = [default_node_pool[0].node_count]
  }

  depends_on = [azurerm_role_assignment.network]
}
