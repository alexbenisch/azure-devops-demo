variable "resource_group_name" {
  type        = string
  description = "Resource Group des Workspace."
}

variable "location" {
  type        = string
  description = "Azure-Region."
}

variable "name_prefix" {
  type        = string
  description = "Präfix für Ressourcen-Namen."
}

variable "retention_in_days" {
  type        = number
  description = "Aufbewahrung der Logs in Tagen."
  default     = 30
}

variable "tags" {
  type        = map(string)
  description = "Ressourcen-Tags."
  default     = {}
}
