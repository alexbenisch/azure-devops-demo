output "vnet_id" {
  description = "ID des VNet."
  value       = azurerm_virtual_network.this.id
}

output "aks_subnet_id" {
  description = "ID des AKS-Subnetzes."
  value       = azurerm_subnet.aks.id
}
