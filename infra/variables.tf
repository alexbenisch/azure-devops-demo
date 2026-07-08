variable "project" {
  type        = string
  description = "Projekt-Kürzel für Ressourcen-Namen (z. B. \"devops\")."
  default     = "devops"

  validation {
    condition     = can(regex("^[a-z0-9]{3,12}$", var.project))
    error_message = "project muss 3-12 Zeichen lang sein (a-z, 0-9)."
  }
}

variable "environment" {
  type        = string
  description = "Umgebung (dev|prod). Steuert Sizing und Tags."

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "environment muss \"dev\" oder \"prod\" sein."
  }
}

variable "location" {
  type        = string
  description = "Azure-Region."
  default     = "westeurope"
}

variable "kubernetes_version" {
  type        = string
  description = "AKS Kubernetes-Version."
  default     = "1.35"
}

variable "aks_vm_size" {
  type        = string
  description = "VM-Größe der AKS-Node-Pools (Referenz: Standard_D2s_v5; Quota-Override möglich)."
  default     = "Standard_D2s_v5"
}

variable "aks_system_node_min" {
  type        = number
  description = "Min. Nodes im System-Pool."
  default     = 1
}

variable "aks_system_node_max" {
  type        = number
  description = "Max. Nodes im System-Pool."
  default     = 3
}

variable "aks_user_node_min" {
  type        = number
  description = "Min. Nodes im User-Pool."
  default     = 1
}

variable "aks_user_node_max" {
  type        = number
  description = "Max. Nodes im User-Pool."
  default     = 5
}

variable "vnet_address_space" {
  type        = list(string)
  description = "Adressraum des VNet."
  default     = ["10.20.0.0/16"]
}

variable "aks_subnet_prefix" {
  type        = string
  description = "Subnetz für die AKS-Node-Pools."
  default     = "10.20.1.0/24"
}

variable "deployer_group_object_id" {
  type        = string
  description = "objectId der AAD-Gruppe, die die AKS-Deployer-Rolle erhält. Leer = Assignment wird übersprungen."
  default     = ""
}

variable "admin_group_object_ids" {
  type        = list(string)
  description = "AAD-Gruppen mit cluster-admin über Azure AD RBAC."
  default     = []
}

variable "tags" {
  type        = map(string)
  description = "Zusätzliche Tags (werden mit common_tags gemerged)."
  default     = {}
}
