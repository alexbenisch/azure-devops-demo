output "cluster_name" {
  description = "Name des AKS-Clusters."
  value       = azurerm_kubernetes_cluster.this.name
}

output "cluster_id" {
  description = "Resource-ID des AKS-Clusters."
  value       = azurerm_kubernetes_cluster.this.id
}

output "oidc_issuer_url" {
  description = "OIDC Issuer URL für Workload Identity Federation."
  value       = azurerm_kubernetes_cluster.this.oidc_issuer_url
}

output "kubelet_identity_object_id" {
  description = "objectId der Kubelet Managed Identity."
  value       = azurerm_kubernetes_cluster.this.kubelet_identity[0].object_id
}

output "node_resource_group" {
  description = "Auto-generierte MC_-Resource-Group der Node-Ressourcen."
  value       = azurerm_kubernetes_cluster.this.node_resource_group
}
