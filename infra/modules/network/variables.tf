

variable "name" {
    description = "Short region code used in resource names, e.g. uks"
    type        = string
}

variable "location" {
  description = "Azure region, e.g. uksouth"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group that will contain the network resources"
  type        = string
}

variable "address_space" {
  description = "VNet address space in CIDR notation, e.g. 10.10.0.0/16"
  type        = string
}

variable "tags" {
  description = "Tags applied to every resource"
  type        = map(string)
  default     = {}
}