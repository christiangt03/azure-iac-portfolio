# Azure IaC Portfolio — Terraform + Multi-Pipeline CI/CD

> **Infraestructura como código en Azure con Terraform, gestionada por dos pipelines paralelos: Azure DevOps y GitHub Actions con autenticación OIDC.**

---

## 🏗️ Arquitectura

```
┌─────────────────────────────────────────────────────────────────┐
│                        Azure (spaincentral)                     │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  Resource Group: rg-portfolio-{dev|prod}                │   │
│  │                                                         │   │
│  │  ┌──────────────┐    ┌──────────────────────────────┐  │   │
│  │  │  VNet        │    │  Key Vault                   │  │   │
│  │  │  10.x.0.0/16 │    │  RBAC habilitado             │  │   │
│  │  │              │    │  Secreto: vm-admin-password  │  │   │
│  │  │  ┌─────────┐ │    └──────────────────────────────┘  │   │
│  │  │  │Subnet   │ │                                       │   │
│  │  │  │Public   │ │    ┌──────────────────────────────┐  │   │
│  │  │  │+ NSG    │ │    │  Storage Account             │  │   │
│  │  │  │         │ │    │  TLS 1.2 / no public access  │  │   │
│  │  │  │ ┌─────┐ │ │    │  Containers: tfstate, backups│  │   │
│  │  │  │ │ VM  │ │ │    └──────────────────────────────┘  │   │
│  │  │  │ │Linux│◄──── password desde Key Vault            │   │
│  │  │  │ └─────┘ │ │                                       │   │
│  │  │  └─────────┘ │                                       │   │
│  │  │  ┌─────────┐ │                                       │   │
│  │  │  │Subnet   │ │                                       │   │
│  │  │  │Private  │ │                                       │   │
│  │  │  └─────────┘ │                                       │   │
│  │  └──────────────┘                                       │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘

CI/CD:
  GitHub Actions  ──OIDC──► Azure AD ──► Terraform ──► Azure
  Azure DevOps    ──SP────► Azure AD ──► Terraform ──► Azure
```

## 📁 Estructura del repositorio

```
azure-iac-portfolio/
├── terraform/
│   ├── modules/
│   │   ├── networking/     # VNet, Subnets, NSG, Public IP
│   │   ├── compute/        # VM Linux (password desde KV)
│   │   ├── keyvault/       # Key Vault con RBAC
│   │   └── storage/        # Storage Account + containers
│   └── environments/
│       ├── dev/            # Entorno DEV (Standard_B1s)
│       └── prod/           # Entorno PROD (Standard_B2s)
├── pipelines/
│   ├── azure-devops/       # azure-pipelines.yml multi-stage
│   └── github-actions/     # terraform-ci-cd.yml con OIDC
├── scripts/
│   ├── setup-backend.sh    # Crea el Storage Account para tfstate
│   └── create-service-principal.sh  # Crea SP con OIDC federado
└── docs/
```

## ⚡ Quick Start

### 1. Prerrequisitos

- Azure CLI instalado y autenticado (`az login`)
- Terraform >= 1.5.0
- Permisos: `Owner` o `Contributor + User Access Administrator` en la Subscription

### 2. Crear el backend (una sola vez)

```bash
chmod +x scripts/setup-backend.sh
./scripts/setup-backend.sh
```

Actualiza los nombres de Storage Account generados en `terraform/environments/{dev,prod}/main.tf` → bloque `backend`.

### 3. Crear el Service Principal con OIDC

```bash
chmod +x scripts/create-service-principal.sh
./scripts/create-service-principal.sh
```

Guarda los valores de salida como **Secrets** en GitHub (`Settings > Secrets and variables > Actions`):

| Secret | Descripción |
|--------|-------------|
| `AZURE_CLIENT_ID` | App ID del Service Principal |
| `AZURE_TENANT_ID` | Tenant ID de Azure AD |
| `AZURE_SUBSCRIPTION_ID` | ID de la Subscription |
| `PIPELINE_PRINCIPAL_ID` | Object ID del SP (para rol en KV) |
| `VM_ADMIN_PASSWORD` | Contraseña de la VM DEV |
| `VM_ADMIN_PASSWORD_PROD` | Contraseña de la VM PROD |
| `TF_STORAGE_ACCOUNT_DEV` | Nombre SA backend DEV |
| `TF_STORAGE_ACCOUNT_PROD` | Nombre SA backend PROD |
| `ALLOWED_SSH_CIDR` | Tu IP para SSH (`x.x.x.x/32`) |

### 4. Deploy manual (sin pipeline)

```bash
cd terraform/environments/dev
cp terraform.tfvars.example terraform.tfvars
# Editar terraform.tfvars con tus valores

terraform init
terraform plan
terraform apply
```

## 🔄 Flujo del Pipeline

### GitHub Actions

```
PR abierto      → validate + plan DEV (comentario en el PR)
Push develop    → validate + plan DEV + apply DEV (con aprobación de Environment)
workflow_dispatch main + prod → plan PROD + apply PROD (con aprobación manual)
```

### Azure DevOps

```
Push develop → Validate → Plan DEV → Apply DEV (aprobación manual)
Push main    → Validate → Plan DEV → Apply DEV → Plan PROD → Apply PROD (aprobación manual)
```

## 🔐 Decisiones de seguridad

| Práctica | Implementación |
|----------|---------------|
| Sin secrets estáticos en GitHub Actions | OIDC Federated Credentials |
| Passwords nunca en código | Azure Key Vault + RBAC |
| tfstate en remoto cifrado | Azure Blob Storage (LRS, TLS 1.2) |
| SSH restringido | NSG con CIDR configurable |
| TLS mínimo en Storage | `min_tls_version = TLS1_2` |
| Blob public access deshabilitado | `allow_blob_public_access = false` |

## 🛠️ Tecnologías usadas

| Tecnología | Versión | Uso |
|------------|---------|-----|
| Terraform | 1.7.x | IaC |
| AzureRM Provider | ~3.90 | Recursos Azure |
| GitHub Actions | — | CI/CD (OIDC) |
| Azure DevOps | — | CI/CD (SP) |
| Azure Key Vault | — | Gestión de secretos |
| Ubuntu 22.04 LTS | Gen2 | VM OS |

---

*Región: `spaincentral` | Autor: [christiangt03](https://github.com/christiangt03)*
