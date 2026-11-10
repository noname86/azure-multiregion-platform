output "vnet_id" {
  description = "ID of the virtual network"
  value       = azurerm_virtual_network.this.id
}

output "subnet_ids" {
  description = "Subnet IDs keyed by purpose"
  value = {
    aks = azurerm_subnet.aks.id
    pls = azurerm_subnet.pls.id
    pe  = azurerm_subnet.pe.id
  }
}