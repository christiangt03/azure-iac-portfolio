output "storage_account_name" {
  value = azurerm_storage_account.sa.name
}

output "storage_account_id" {
  value = azurerm_storage_account.sa.id
}

output "tfstate_container_name" {
  value = azurerm_storage_container.tfstate.name
}

output "primary_blob_endpoint" {
  value = azurerm_storage_account.sa.primary_blob_endpoint
}
