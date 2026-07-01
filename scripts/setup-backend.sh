#!/bin/bash
# ==============================================================
# setup-backend.sh
# Crea el backend de Terraform (Storage Account para tfstate)
# Ejecutar UNA VEZ antes de hacer terraform init
# ==============================================================

set -euo pipefail

RESOURCE_GROUP="rg-tfstate"
LOCATION="spaincentral"
STORAGE_ACCOUNT_DEV="portfoliosadev$(openssl rand -hex 4)"
STORAGE_ACCOUNT_PROD="portfoliosaprod$(openssl rand -hex 4)"
CONTAINER_NAME="tfstate"

echo "🔧 Creando backend para Terraform state..."

# Resource Group para el estado
az group create \
  --name "$RESOURCE_GROUP" \
  --location "$LOCATION" \
  --tags managed_by=terraform project=azure-iac-portfolio

# Storage Account DEV
az storage account create \
  --name "$STORAGE_ACCOUNT_DEV" \
  --resource-group "$RESOURCE_GROUP" \
  --location "$LOCATION" \
  --sku Standard_LRS \
  --kind StorageV2 \
  --https-only true \
  --min-tls-version TLS1_2 \
  --allow-blob-public-access false

# Storage Account PROD
az storage account create \
  --name "$STORAGE_ACCOUNT_PROD" \
  --resource-group "$RESOURCE_GROUP" \
  --location "$LOCATION" \
  --sku Standard_LRS \
  --kind StorageV2 \
  --https-only true \
  --min-tls-version TLS1_2 \
  --allow-blob-public-access false

# Containers
for SA in "$STORAGE_ACCOUNT_DEV" "$STORAGE_ACCOUNT_PROD"; do
  az storage container create \
    --name "$CONTAINER_NAME" \
    --account-name "$SA" \
    --auth-mode login
done

echo ""
echo "✅ Backend creado exitosamente"
echo "──────────────────────────────────────"
echo "DEV  Storage Account: $STORAGE_ACCOUNT_DEV"
echo "PROD Storage Account: $STORAGE_ACCOUNT_PROD"
echo ""
echo "📝 Actualiza estos valores en:"
echo "   - terraform/environments/dev/main.tf  → backend block"
echo "   - terraform/environments/prod/main.tf → backend block"
echo "   - Secrets del pipeline (TF_STORAGE_ACCOUNT_DEV / PROD)"
