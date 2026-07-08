variable "resource_group_name" {
  type        = string
  description = "Resource Group des Key Vault."
}

variable "location" {
  type        = string
  description = "Azure-Region."
}

variable "name_prefix" {
  type        = string
  description = "Präfix für den Vault-Namen."
}

variable "tenant_id" {
  type        = string
  description = "AAD Tenant ID."
}

variable "admin_object_id" {
  type        = string
  description = "objectId des Prinzipals, der initial Secret-Rechte erhält (z. B. der CI-Deployer)."
}

variable "tags" {
  type        = map(string)
  description = "Ressourcen-Tags."
  default     = {}
}
