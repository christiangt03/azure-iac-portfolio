# ==============================================================
# Module: storage
# Crea: Storage Account + Container para tfstate remoto / backups
# ==============================================================

resource "azurerm_storage_account" "sa" {
  name                     = lower(replace("${var.prefix}sa${var.environment}", "-", ""))
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  # Buenas prácticas de seguridad
  allow_nested_items_to_be_public = false
  https_traffic_only_enabled      = true
  min_tls_version                 = "TLS1_2"

  blob_properties {
    versioning_enabled = true

    delete_retention_policy {
      days = 7
    }
  }

  tags = var.tags
}

resource "azurerm_storage_container" "tfstate" {
  name                  = "tfstate"
  storage_account_name  = azurerm_storage_account.sa.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "backups" {
  name                  = "backups"
  storage_account_name  = azurerm_storage_account.sa.name
  container_access_type = "private"
}
