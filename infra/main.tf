data "azurerm_client_config" "current" {}

locals {
  common_tags = merge(
    {
      project     = var.project
      environment = var.environment
      managed_by  = "terraform"
      demo        = "azure-devops"
    },
    var.tags,
  )

  name_prefix = "${var.project}-${var.environment}"
}

resource "azurerm_resource_group" "this" {
  name     = "rg-${local.name_prefix}"
  location = var.location
  tags     = local.common_tags
}

module "network" {
  source              = "./modules/network"
  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
  name_prefix         = local.name_prefix
  address_space       = var.vnet_address_space
  aks_subnet_prefix   = var.aks_subnet_prefix
  tags                = local.common_tags
}

module "monitoring" {
  source              = "./modules/monitoring"
  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
  name_prefix         = local.name_prefix
  tags                = local.common_tags
}

module "acr" {
  source              = "./modules/acr"
  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
  # ACR-Namen müssen global eindeutig & alphanumerisch sein.
  registry_name = "acr${var.project}${var.environment}"
  tags          = local.common_tags
}

module "keyvault" {
  source              = "./modules/keyvault"
  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
  name_prefix         = local.name_prefix
  tenant_id           = data.azurerm_client_config.current.tenant_id
  admin_object_id     = data.azurerm_client_config.current.object_id
  tags                = local.common_tags
}

module "aks" {
  source                 = "./modules/aks"
  resource_group_name    = azurerm_resource_group.this.name
  location               = var.location
  cluster_name           = "aks-${local.name_prefix}"
  kubernetes_version     = var.kubernetes_version
  subnet_id              = module.network.aks_subnet_id
  acr_id                 = module.acr.id
  log_analytics_id       = module.monitoring.workspace_id
  admin_group_object_ids = var.admin_group_object_ids
  tags                   = local.common_tags
}

module "rbac" {
  source                   = "./modules/rbac"
  subscription_scope       = "/subscriptions/${data.azurerm_client_config.current.subscription_id}"
  resource_group_id        = azurerm_resource_group.this.id
  acr_id                   = module.acr.id
  deployer_group_object_id = var.deployer_group_object_id
}
