variable "allowed_ssh_cidr" {
  description = "IP o CIDR permitido para SSH"
  type        = string
  default     = "0.0.0.0/0"
}

variable "pipeline_principal_id" {
  description = "Object ID del SP del pipeline CI/CD"
  type        = string
}

variable "vm_admin_password" {
  description = "Contraseña del admin de la VM (mínimo 12 chars)"
  type        = string
  sensitive   = true
}
