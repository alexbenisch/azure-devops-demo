output "id" {
  description = "Resource-ID des Key Vault."
  value       = azurerm_key_vault.this.id
}

output "vault_uri" {
  description = "URI des Key Vault (für den CSI Secret Store Driver)."
  value       = azurerm_key_vault.this.vault_uri
}

output "name" {
  description = "Name des Key Vault."
  value       = azurerm_key_vault.this.name
}
