resource "azurerm_kubernetes_cluster" "this" {
  name                = var.cluster_name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = var.cluster_name
  kubernetes_version  = var.kubernetes_version

  # OIDC + Workload Identity => keine statischen Secrets im Cluster.
  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  # Kein lokaler admin-Account => Zugriff ausschließlich über AAD.
  local_account_disabled = true

  default_node_pool {
    name                         = "system"
    vm_size                      = "Standard_D2s_v5"
    enable_auto_scaling          = true
    min_count                    = 1
    max_count                    = 3
    vnet_subnet_id               = var.subnet_id
    orchestrator_version         = var.kubernetes_version
    only_critical_addons_enabled = true

    upgrade_settings {
      max_surge = "33%"
    }
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "azure"
    network_policy    = "calico"
    load_balancer_sku = "standard"
  }

  # Container Insights => proaktives Monitoring.
  oms_agent {
    log_analytics_workspace_id = var.log_analytics_id
  }

  # Azure AD RBAC für Kubernetes-Autorisierung.
  azure_active_directory_role_based_access_control {
    azure_rbac_enabled     = true
    admin_group_object_ids = var.admin_group_object_ids
  }

  workload_autoscaler_profile {
    keda_enabled = true
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [
      # kubernetes_version wird über auto-upgrade gepflegt, nicht per apply zurückgesetzt.
      kubernetes_version,
    ]
  }
}

# Eigener User-Node-Pool für Workloads (System-Pool bleibt für kube-system reserviert).
resource "azurerm_kubernetes_cluster_node_pool" "user" {
  name                  = "user"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.this.id
  vm_size               = "Standard_D2s_v5"
  enable_auto_scaling   = true
  min_count             = 1
  max_count             = 5
  vnet_subnet_id        = var.subnet_id
  orchestrator_version  = var.kubernetes_version
  mode                  = "User"
  tags                  = var.tags
}

# ACR-Pull ohne imagePullSecrets — via Kubelet Managed Identity.
resource "azurerm_role_assignment" "acr_pull" {
  scope                            = var.acr_id
  role_definition_name             = "AcrPull"
  principal_id                     = azurerm_kubernetes_cluster.this.kubelet_identity[0].object_id
  skip_service_principal_aad_check = true
}
