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

  # Entra ID object IDs with cluster admin rights (not secrets)
  aks_admin_object_ids = ["82197347-13a7-48e4-876b-8374ab0782af"]
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

module "aks" {
  source   = "../../modules/aks"
  for_each = var.aks_enabled ? local.regions : {}

  name                = each.key
  location            = each.value.location
  resource_group_name = azurerm_resource_group.region[each.key].name
  vnet_id             = module.network[each.key].vnet_id
  subnet_id           = module.network[each.key].subnet_ids.aks
  admin_object_ids    = local.aks_admin_object_ids
  tags                = local.tags
}