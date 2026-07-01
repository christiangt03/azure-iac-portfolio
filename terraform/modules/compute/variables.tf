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

variable "subnet_id" {
  type = string
}

variable "public_ip_id" {
  type = string
}

variable "key_vault_id" {
  type = string
}

variable "vm_password_secret_name" {
  type = string
}

variable "vm_size" {
  type    = string
  default = "Standard_B1s"
}

variable "admin_username" {
  type    = string
  default = "azureadmin"
}

variable "tags" {
  type    = map(string)
  default = {}
}
