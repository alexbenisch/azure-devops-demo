output "workspace_id" {
  description = "Resource-ID des Log Analytics Workspace."
  value       = azurerm_log_analytics_workspace.this.id
}

output "workspace_name" {
  description = "Name des Log Analytics Workspace."
  value       = azurerm_log_analytics_workspace.this.name
}

output "action_group_id" {
  description = "Resource-ID der Action Group (Alert-Ziel)."
  value       = azurerm_monitor_action_group.platform.id
}
