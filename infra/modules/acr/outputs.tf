output "id" {
  description = "Resource-ID der ACR."
  value       = azurerm_container_registry.this.id
}

output "login_server" {
  description = "Login-Server der ACR (z. B. acrdevopsdev.azurecr.io)."
  value       = azurerm_container_registry.this.login_server
}

output "name" {
  description = "Name der ACR."
  value       = azurerm_container_registry.this.name
}
