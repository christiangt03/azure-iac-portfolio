output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "resource_group_location" {
  value = azurerm_resource_group.rg.location
}

output "vnet_id" {
  value = azurerm_virtual_network.vnet.id
}

output "subnet_public_id" {
  value = azurerm_subnet.subnet_public.id
}

output "subnet_private_id" {
  value = azurerm_subnet.subnet_private.id
}

output "public_ip_address" {
  value = azurerm_public_ip.pip.ip_address
}

output "public_ip_id" {
  value = azurerm_public_ip.pip.id
}
