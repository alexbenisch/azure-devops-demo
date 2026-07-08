variable "resource_group_name" {
  type        = string
  description = "Resource Group für die Netzwerk-Ressourcen."
}

variable "location" {
  type        = string
  description = "Azure-Region."
}

variable "name_prefix" {
  type        = string
  description = "Präfix für Ressourcen-Namen (project-environment)."
}

variable "address_space" {
  type        = list(string)
  description = "VNet-Adressraum."
}

variable "aks_subnet_prefix" {
  type        = string
  description = "Adress-Präfix des AKS-Subnetzes."
}

variable "tags" {
  type        = map(string)
  description = "Ressourcen-Tags."
  default     = {}
}
