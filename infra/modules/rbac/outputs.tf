output "aks_deployer_role_id" {
  description = "Resource-ID der AKS-Deployer Custom Role."
  value       = azurerm_role_definition.aks_deployer.role_definition_resource_id
}
