variable "subscription_scope" {
  type        = string
  description = "Subscription-Scope (/subscriptions/<id>) für die Custom Role."
}

variable "resource_group_id" {
  type        = string
  description = "Resource-Group-ID, auf die die Rolle zugewiesen wird."
}

variable "acr_id" {
  type        = string
  description = "ACR-Resource-ID (für die Pull-Berechtigung des Deployers)."
}

variable "deployer_group_object_id" {
  type        = string
  description = "objectId der AAD-Deployer-Gruppe. Leer => Assignment wird übersprungen."
  default     = ""
}
