locals {
  regions = {
    uks = {
      location      = "uksouth"
      address_space = "10.10.0.0/16"
    }
    neu = {
      location      = "northeurope"
      address_space = "10.20.0.0/16"
    }
  }

  tags = {
    project     = "azure-multiregion-platform"
    environment = "dev"
    managed_by  = "terraform"
  }
}

resource "azurerm_resource_group" "region" {
  for_each = local.regions

  name     = "rg-platform-dev-${each.key}"
  location = each.value.location
  tags     = local.tags
}

module "network" {
  source   = "../../modules/network"
  for_each = local.regions

  name                = each.key
  location            = each.value.location
  resource_group_name = azurerm_resource_group.region[each.key].name
  address_space       = each.value.address_space
  tags                = local.tags
}