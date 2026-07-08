variable "resource_group_name" {
  type        = string
  description = "Resource Group des Clusters."
}

variable "location" {
  type        = string
  description = "Azure-Region."
}

variable "cluster_name" {
  type        = string
  description = "Name des AKS-Clusters."
}

variable "kubernetes_version" {
  type        = string
  description = "Kubernetes-Version."
}

variable "subnet_id" {
  type        = string
  description = "Subnetz-ID für die Node-Pools."
}

variable "acr_id" {
  type        = string
  description = "ACR-Resource-ID für die AcrPull-Zuweisung."
}

variable "log_analytics_id" {
  type        = string
  description = "Log Analytics Workspace ID für Container Insights."
}

variable "admin_group_object_ids" {
  type        = list(string)
  description = "AAD-Gruppen mit cluster-admin."
  default     = []
}

variable "vm_size" {
  type        = string
  description = "VM-Größe der Node-Pools. Referenz-Design: D-Serie; für Quota-limitierte Subscriptions überschreibbar (z. B. Standard_B2ms)."
  default     = "Standard_D2s_v5"
}

variable "system_node_min" {
  type        = number
  description = "Min. Nodes im System-Pool."
  default     = 1
}

variable "system_node_max" {
  type        = number
  description = "Max. Nodes im System-Pool."
  default     = 3
}

variable "user_node_min" {
  type        = number
  description = "Min. Nodes im User-Pool."
  default     = 1
}

variable "user_node_max" {
  type        = number
  description = "Max. Nodes im User-Pool."
  default     = 5
}

variable "tags" {
  type        = map(string)
  description = "Ressourcen-Tags."
  default     = {}
}
