# ==============================================================
# Module: keyvault
# Crea: Key Vault con acceso basado en políticas (RBAC-ready)
# ==============================================================

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "kv" {
  name                       = "${var.prefix}-kv-${var.environment}"
  location                   = var.location
  resource_group_name        = var.resource_group_name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 7
  purge_protection_enabled   = false # true en producción real

  # Habilitar RBAC en lugar de access policies
  enable_rbac_authorization = true

  network_acls {
    default_action = "Allow"
    bypass         = "AzureServices"
  }

  tags = var.tags
}

# Asignar rol "Key Vault Secrets User" al service principal del pipeline
resource "azurerm_role_assignment" "kv_secrets_user" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = var.pipeline_principal_id
}

# Asignar rol "Key Vault Administrator" al deployer (tú)
resource "azurerm_role_assignment" "kv_admin" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azurerm_client_config.current.object_id
}

# Secreto de ejemplo: VM admin password (viene de variable sensible)
resource "azurerm_key_vault_secret" "vm_admin_password" {
  name         = "vm-admin-password"
  value        = var.vm_admin_password
  key_vault_id = azurerm_key_vault.kv.id

  depends_on = [azurerm_role_assignment.kv_admin]
}
