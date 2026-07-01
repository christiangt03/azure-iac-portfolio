# ==============================================================
# Environment: DEV
# Llama a todos los módulos con configuración para desarrollo
# CI smoke test: valida login OIDC + plan DEV en PR (sin cambios de infra)
# ==============================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.90"
    }
  }

  # Backend remoto en Azure Blob Storage
  backend "azurerm" {
    resource_group_name  = "rg-tfstate"
    storage_account_name = "portfoliosadev6d081c4f"
    container_name       = "tfstate"
    key                  = "dev/terraform.tfstate"
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
  }
}

locals {
  prefix      = "portfolio"
  environment = "dev"
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
  vnet_address_space  = ["10.0.0.0/16"]
  subnet_public_cidr  = "10.0.1.0/24"
  subnet_private_cidr = "10.0.2.0/24"
  allowed_ssh_cidr    = var.allowed_ssh_cidr
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
  vm_size                 = "Standard_B1s"
  tags                    = local.tags
}
