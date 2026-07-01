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

variable "tags" {
  type    = map(string)
  default = {}
}
