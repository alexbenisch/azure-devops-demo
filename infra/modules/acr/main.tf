# ACR-Namen müssen global eindeutig sein — Suffix gegen Kollisionen.
resource "random_string" "suffix" {
  length  = 5
  special = false
  upper   = false
}

resource "azurerm_container_registry" "this" {
  name                = "${var.registry_name}${random_string.suffix.result}"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.sku

  # Admin-User deaktiviert => Zugriff nur über Azure AD / Managed Identity.
  admin_enabled = false

  tags = var.tags
}
