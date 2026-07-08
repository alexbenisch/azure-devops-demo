variable "resource_group_name" {
  type        = string
  description = "Resource Group der Registry."
}

variable "location" {
  type        = string
  description = "Azure-Region."
}

variable "registry_name" {
  type        = string
  description = "Global eindeutiger, alphanumerischer ACR-Name."
}

variable "sku" {
  type        = string
  description = "ACR SKU (Basic|Standard|Premium)."
  default     = "Standard"
}

variable "tags" {
  type        = map(string)
  description = "Ressourcen-Tags."
  default     = {}
}
