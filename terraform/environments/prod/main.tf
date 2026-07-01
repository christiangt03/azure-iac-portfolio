# ==============================================================
# Environment: PROD
# Misma arquitectura con sizing mayor y restricciones de seguridad
# ==============================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.90"
    }
  }

  backend "azurerm" {
    resource_group_name  = "rg-tfstate"
    storage_account_name = "portfoliosaprod" # cambiar por el real
    container_name       = "tfstate"
    key                  = "prod/terraform.tfstate"
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = true
    }
  }
}

locals {
  prefix      = "portfolio"
  environment = "prod"
  location    = "spaincentral"

  tags = {
    environment = local.environment
    project     = "azure-iac-portfolio"
    owner       = "christiangt03"
    managed_by  = "terraform"
  }
}

module "networking" {
  source = "../../modules/networking"

  prefix              = local.prefix
  location            = local.location
  resource_group_name = "rg-${local.prefix}-${local.environment}"
  vnet_address_space  = ["10.1.0.0/16"]
  subnet_public_cidr  = "10.1.1.0/24"
  subnet_private_cidr = "10.1.2.0/24"
  allowed_ssh_cidr    = var.allowed_ssh_cidr # IP fija en prod
  tags                = local.tags
}

module "storage" {
  source = "../../modules/storage"

  prefix              = local.prefix
  environment         = local.environment
  location            = local.location
  resource_group_name = module.networking.resource_group_name
  tags                = local.tags
}

module "keyvault" {
  source = "../../modules/keyvault"

  prefix                = local.prefix
  environment           = local.environment
  location              = local.location
  resource_group_name   = module.networking.resource_group_name
  pipeline_principal_id = var.pipeline_principal_id
  kv_admin_object_id    = var.kv_admin_object_id
  vm_admin_password     = var.vm_admin_password
  tags                  = local.tags
}

module "compute" {
  source = "../../modules/compute"

  prefix                  = local.prefix
  environment             = local.environment
  location                = local.location
  resource_group_name     = module.networking.resource_group_name
  subnet_id               = module.networking.subnet_public_id
  public_ip_id            = module.networking.public_ip_id
  key_vault_id            = module.keyvault.key_vault_id
  vm_password_secret_name = module.keyvault.vm_password_secret_name
  vm_size                 = "Standard_B2s" # más grande en prod
  tags                    = local.tags
}
