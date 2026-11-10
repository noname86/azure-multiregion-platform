output "aks_clusters" {
  description = "AKS cluster names and resource groups, keyed by region"
  value = {
    for k, m in module.aks : k => {
      name           = m.name
      resource_group = azurerm_resource_group.region[k].name
    }
  }
}