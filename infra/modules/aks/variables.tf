variable "name" {
  description = "Short region code used in resource names, e.g. uks"
  type        = string
}

variable "location" {
  description = "Azure region, e.g. uksouth"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group that will contain the cluster"
  type        = string
}

variable "vnet_id" {
  description = "ID of the VNet the cluster uses (scope for the network role)"
  type        = string
}

variable "subnet_id" {
  description = "ID of the subnet for the cluster nodes"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes minor version; patches are applied automatically"
  type        = string
  default     = "1.36"
}

variable "node_vm_size" {
  description = "VM size of the system node pool"
  type        = string
}

variable "node_count" {
  description = "Number of nodes in the system node pool"
  type        = number
  default     = 1
}

variable "admin_object_ids" {
  description = "Entra ID object IDs granted cluster admin via Azure RBAC"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags applied to every resource"
  type        = map(string)
  default     = {}
}