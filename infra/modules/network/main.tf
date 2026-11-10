locals {
  # Carve three /24 subnets out of the /16 address space
  subnets = {
    aks = cidrsubnet(var.address_space, 8, 0)
    pls = cidrsubnet(var.address_space, 8, 1)
    pe  = cidrsubnet(var.address_space, 8, 2)
  }
}

resource "azurerm_virtual_network" "this" {
  name                = "vnet-${var.name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = [var.address_space]
  tags                = var.tags
}

resource "azurerm_subnet" "aks" {
  name                 = "snet-aks"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [local.subnets.aks]
}

resource "azurerm_subnet" "pls" {
  name                 = "snet-pls"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [local.subnets.pls]

  # Required to host a Private Link Service
  private_link_service_network_policies_enabled = false
}

resource "azurerm_subnet" "pe" {
  name                 = "snet-pe"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [local.subnets.pe]
}

resource "azurerm_network_security_group" "aks" {
  name                = "nsg-aks-${var.name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_subnet_network_security_group_association" "aks" {
  subnet_id                 = azurerm_subnet.aks.id
  network_security_group_id = azurerm_network_security_group.aks.id
}