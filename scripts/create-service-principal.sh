#!/bin/bash
# ==============================================================
# create-service-principal.sh
# Crea el SP para CI/CD con OIDC (GitHub Actions) y permisos mínimos
# ==============================================================

set -euo pipefail

APP_NAME="sp-portfolio-cicd"
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
GITHUB_ORG="christiangt03"
GITHUB_REPO="azure-iac-portfolio"

echo "🔐 Creando Service Principal para CI/CD..."

# Crear la App Registration
APP_ID=$(az ad app create --display-name "$APP_NAME" --query appId -o tsv)
echo "App ID: $APP_ID"

# Crear el Service Principal
SP_OBJECT_ID=$(az ad sp create --id "$APP_ID" --query id -o tsv)
echo "SP Object ID: $SP_OBJECT_ID"

# Asignar rol Contributor a nivel de Subscription
az role assignment create \
  --role "Contributor" \
  --assignee-object-id "$SP_OBJECT_ID" \
  --assignee-principal-type ServicePrincipal \
  --scope "/subscriptions/$SUBSCRIPTION_ID"

# Configurar federated credential para GitHub Actions (OIDC)
# Para branch main
az ad app federated-credential create \
  --id "$APP_ID" \
  --parameters "{
    \"name\": \"github-main\",
    \"issuer\": \"https://token.actions.githubusercontent.com\",
    \"subject\": \"repo:${GITHUB_ORG}/${GITHUB_REPO}:ref:refs/heads/main\",
    \"description\": \"GitHub Actions OIDC - main branch\",
    \"audiences\": [\"api://AzureADTokenExchange\"]
  }"

# Para branch develop
az ad app federated-credential create \
  --id "$APP_ID" \
  --parameters "{
    \"name\": \"github-develop\",
    \"issuer\": \"https://token.actions.githubusercontent.com\",
    \"subject\": \"repo:${GITHUB_ORG}/${GITHUB_REPO}:ref:refs/heads/develop\",
    \"description\": \"GitHub Actions OIDC - develop branch\",
    \"audiences\": [\"api://AzureADTokenExchange\"]
  }"

# Para Pull Requests
az ad app federated-credential create \
  --id "$APP_ID" \
  --parameters "{
    \"name\": \"github-pr\",
    \"issuer\": \"https://token.actions.githubusercontent.com\",
    \"subject\": \"repo:${GITHUB_ORG}/${GITHUB_REPO}:pull_request\",
    \"description\": \"GitHub Actions OIDC - Pull Requests\",
    \"audiences\": [\"api://AzureADTokenExchange\"]
  }"

TENANT_ID=$(az account show --query tenantId -o tsv)

echo ""
echo "✅ Service Principal creado con OIDC"
echo "──────────────────────────────────────"
echo "Guarda estos valores en los Secrets de GitHub/Azure DevOps:"
echo ""
echo "AZURE_CLIENT_ID:       $APP_ID"
echo "AZURE_TENANT_ID:       $TENANT_ID"
echo "AZURE_SUBSCRIPTION_ID: $SUBSCRIPTION_ID"
echo "PIPELINE_PRINCIPAL_ID: $SP_OBJECT_ID"
echo ""
echo "⚠️  NO se generó ningún client_secret (OIDC no lo necesita)"
