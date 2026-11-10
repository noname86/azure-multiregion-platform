variable "aks_enabled" {
  description = "Create the AKS clusters. Set to false to tear them down and stop the costs."
  type        = bool
  default     = false
}