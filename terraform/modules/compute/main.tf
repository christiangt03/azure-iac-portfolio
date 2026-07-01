# ==============================================================
# Module: compute
# Crea: NIC + Linux VM (Ubuntu 22.04) con password desde Key Vault
# ==============================================================

data "azurerm_key_vault_secret" "vm_password" {
  name         = var.vm_password_secret_name
  key_vault_id = var.key_vault_id
}

resource "azurerm_network_interface" "nic" {
  name                = "${var.prefix}-nic"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = var.public_ip_id
  }

  tags = var.tags
}

resource "azurerm_linux_virtual_machine" "vm" {
  name                = "${var.prefix}-vm-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  size                = var.vm_size
  admin_username      = var.admin_username
  admin_password      = data.azurerm_key_vault_secret.vm_password.value

  disable_password_authentication = false

  network_interface_ids = [azurerm_network_interface.nic.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 30
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  tags = var.tags
}
