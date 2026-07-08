resource "azurerm_log_analytics_workspace" "this" {
  name                = "log-${var.name_prefix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "PerGB2018"
  retention_in_days   = var.retention_in_days
  tags                = var.tags
}

# ContainerInsights-Lösung — liefert die Container-Insights-Dashboards im Portal.
resource "azurerm_log_analytics_solution" "container_insights" {
  solution_name         = "ContainerInsights"
  resource_group_name   = var.resource_group_name
  location              = var.location
  workspace_resource_id = azurerm_log_analytics_workspace.this.id
  workspace_name        = azurerm_log_analytics_workspace.this.name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/ContainerInsights"
  }

  tags = var.tags
}

# Action Group als Ziel für Alerts (E-Mail an das Platform-Team).
resource "azurerm_monitor_action_group" "platform" {
  name                = "ag-${var.name_prefix}"
  resource_group_name = var.resource_group_name
  short_name          = "platform"

  email_receiver {
    name          = "platform-oncall"
    email_address = "platform-oncall@demo.local"
  }

  tags = var.tags
}
