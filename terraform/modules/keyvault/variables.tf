variable "prefix" {
  type = string
}

variable "environment" {
  type = string
}

variable "location" {
  type    = string
  default = "spaincentral"
}

variable "resource_group_name" {
  type = string
}

variable "pipeline_principal_id" {
  description = "Object ID del Service Principal usado por el pipeline CI/CD"
  type        = string
}

variable "kv_admin_object_id" {
  description = "Object ID estable que recibe 'Key Vault Administrator'. Si se deja vacío, usa la identidad que ejecuta Terraform (provoca drift si distintos identities aplican)."
  type        = string
  default     = ""
}

variable "vm_admin_password" {
  description = "Contraseña del admin de la VM (se guarda en Key Vault)"
  type        = string
  sensitive   = true
}

variable "tags" {
  type    = map(string)
  default = {}
}
