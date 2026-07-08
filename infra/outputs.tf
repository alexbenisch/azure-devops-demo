output "resource_group_name" {
  description = "Name der zentralen Resource Group."
  value       = azurerm_resource_group.this.name
}

output "aks_cluster_name" {
  description = "Name des AKS-Clusters (für az aks get-credentials)."
  value       = module.aks.cluster_name
}

output "aks_oidc_issuer_url" {
  description = "OIDC Issuer URL (für Workload Identity Federation)."
  value       = module.aks.oidc_issuer_url
}

output "acr_login_server" {
  description = "ACR Login-Server (z. B. acrdevopsdemo.azurecr.io)."
  value       = module.acr.login_server
}

output "key_vault_uri" {
  description = "Key Vault URI (für CSI Secret Store Driver)."
  value       = module.keyvault.vault_uri
}

output "log_analytics_workspace_id" {
  description = "Log Analytics Workspace ID (Container Insights / KQL)."
  value       = module.monitoring.workspace_id
}
