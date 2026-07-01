variable "prefix" {
  description = "Prefijo para todos los recursos"
  type        = string
}

variable "location" {
  description = "Región de Azure"
  type        = string
  default     = "spaincentral"
}

variable "resource_group_name" {
  description = "Nombre del Resource Group"
  type        = string
}

variable "vnet_address_space" {
  description = "CIDR de la VNet"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "subnet_public_cidr" {
  description = "CIDR de la subred pública"
  type        = string
  default     = "10.0.1.0/24"
}

variable "subnet_private_cidr" {
  description = "CIDR de la subred privada"
  type        = string
  default     = "10.0.2.0/24"
}

variable "allowed_ssh_cidr" {
  description = "CIDR permitido para SSH (usa tu IP o VPN)"
  type        = string
  default     = "0.0.0.0/0" # cambiar en producción
}

variable "tags" {
  description = "Tags comunes para todos los recursos"
  type        = map(string)
  default     = {}
}
