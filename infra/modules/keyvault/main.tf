resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

resource "azurerm_key_vault" "this" {
  # Key-Vault-Namen sind global eindeutig & max. 24 Zeichen — Suffix gegen Kollisionen.
  name                = substr("kv-${var.name_prefix}-${random_string.suffix.result}", 0, 24)
  resource_group_name = var.resource_group_name
  location            = var.location
  tenant_id           = var.tenant_id
  sku_name            = "standard"

  # RBAC-Autorisierung statt Access Policies => konsistent mit Azure RBAC.
  enable_rbac_authorization = true

  purge_protection_enabled   = false
  soft_delete_retention_days = 7

  tags = var.tags
}

# Der Bootstrap-Prinzipal darf Secrets verwalten (für Demo-Seed-Werte).
resource "azurerm_role_assignment" "admin_secrets" {
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = var.admin_object_id
}

# Beispiel-Secret, das die App später via CSI Secret Store Driver zieht.
resource "azurerm_key_vault_secret" "sample" {
  name         = "sample-api-greeting"
  value        = "Hallo aus dem Key Vault"
  key_vault_id = azurerm_key_vault.this.id

  depends_on = [azurerm_role_assignment.admin_secrets]
}
