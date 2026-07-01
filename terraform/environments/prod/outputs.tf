output "public_ip" {
  description = "IP pública de la VM"
  value       = module.networking.public_ip_address
}

output "vm_name" {
  description = "Nombre de la VM desplegada"
  value       = module.compute.vm_name
}

output "key_vault_uri" {
  description = "URI del Key Vault"
  value       = module.keyvault.key_vault_uri
}

output "storage_account_name" {
  description = "Nombre del Storage Account"
  value       = module.storage.storage_account_name
}
