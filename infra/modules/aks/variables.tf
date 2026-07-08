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

variable "tags" {
  type        = map(string)
  description = "Ressourcen-Tags."
  default     = {}
}
