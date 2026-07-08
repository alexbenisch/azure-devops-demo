locals {
  assign_deployer = var.deployer_group_object_id != ""
}

# Custom Role: darf AKS lesen & deployen, aber keine Infrastruktur löschen (Least Privilege).
resource "azurerm_role_definition" "aks_deployer" {
  name        = "AKS Deployer (Demo)"
  scope       = var.subscription_scope
  description = "Darf AKS lesen & Credentials ziehen, aber keinen Cluster löschen."

  permissions {
    actions = [
      "Microsoft.ContainerService/managedClusters/read",
      "Microsoft.ContainerService/managedClusters/listClusterUserCredential/action",
      "Microsoft.ContainerRegistry/registries/pull/read",
    ]
    not_actions = [
      "Microsoft.ContainerService/managedClusters/delete",
    ]
  }

  assignable_scopes = [var.subscription_scope]
}

# Zuweisung an eine AAD-Gruppe (nie an Einzelnutzer) — nur wenn objectId gesetzt.
resource "azurerm_role_assignment" "deployer" {
  count              = local.assign_deployer ? 1 : 0
  scope              = var.resource_group_id
  role_definition_id = azurerm_role_definition.aks_deployer.role_definition_resource_id
  principal_id       = var.deployer_group_object_id
}

# Explizite AcrPull-Zuweisung für die Deployer-Gruppe (z. B. für lokale docker pulls).
resource "azurerm_role_assignment" "deployer_acr_pull" {
  count                = local.assign_deployer ? 1 : 0
  scope                = var.acr_id
  role_definition_name = "AcrPull"
  principal_id         = var.deployer_group_object_id
}
