<#
.SYNOPSIS
    Despliega el entorno DEV de azure-iac-portfolio en Azure, de cero y en un solo paso.

.DESCRIPTION
    Idempotente y auto-suficiente:
      1. Verifica la sesión de Azure y fija la suscripción.
      2. Crea el backend remoto de Terraform (rg-tfstate + Storage Account + container) si no existe.
      3. Genera terraform.tfvars detectando tu IP pública y tu identidad (no hay que editar nada a mano).
      4. terraform init + apply.

.EXAMPLE
    .\scripts\deploy-dev.ps1
#>

$ErrorActionPreference = 'Stop'

# ----------------------- Configuración -----------------------
$SubscriptionId = 'ed313ee9-11b5-45d4-ac7c-6116fc894139'
$TenantId       = '952b5ee7-d646-4665-bcda-c47226bc38e5'
$Location       = 'spaincentral'
$TfstateRg      = 'rg-tfstate'
$BackendSa      = 'portfoliosadev6d081c4f'   # debe coincidir con el bloque backend de dev/main.tf
$Container      = 'tfstate'
$SpDisplayName  = 'sp-portfolio-cicd'
$DevDir         = Join-Path $PSScriptRoot '..\terraform\environments\dev'
# -------------------------------------------------------------

function Step($n, $msg) { Write-Host "==> $n  $msg" -ForegroundColor Cyan }

# 1. Sesión de Azure
Step '1/5' 'Verificando sesión de Azure...'
$acc = az account show -o json 2>$null | ConvertFrom-Json
if (-not $acc) {
    Write-Host "    No hay sesión activa. Inicia con:" -ForegroundColor Yellow
    Write-Host "    az login --tenant $TenantId"
    exit 1
}
az account set --subscription $SubscriptionId | Out-Null
Write-Host "    Cuenta: $($acc.user.name)  |  Suscripción: $SubscriptionId"

# 2. Backend remoto (crear si falta)
Step '2/5' 'Asegurando backend remoto (tfstate)...'
az group create --name $TfstateRg --location $Location --only-show-errors | Out-Null
$saExists = az storage account show --name $BackendSa --resource-group $TfstateRg --query name -o tsv 2>$null
if (-not $saExists) {
    Write-Host "    Creando Storage Account $BackendSa..."
    az storage account create --name $BackendSa --resource-group $TfstateRg --location $Location `
        --sku Standard_LRS --kind StorageV2 --https-only true --min-tls-version TLS1_2 `
        --allow-blob-public-access false --only-show-errors | Out-Null
    $key = az storage account keys list --resource-group $TfstateRg --account-name $BackendSa --query '[0].value' -o tsv
    az storage container create --name $Container --account-name $BackendSa --account-key $key --only-show-errors | Out-Null
    Write-Host "    Backend creado."
} else {
    Write-Host "    Backend ya existe."
}

# 3. terraform.tfvars (auto-generado)
Step '3/5' 'Generando terraform.tfvars...'
$tfvars = Join-Path $DevDir 'terraform.tfvars'
$myIp   = (Invoke-RestMethod -Uri 'https://api.ipify.org').ToString().Trim()
$myOid  = az ad signed-in-user show --query id -o tsv
$spOid  = az ad sp list --display-name $SpDisplayName --query '[0].id' -o tsv 2>$null
if ([string]::IsNullOrWhiteSpace($spOid)) { $spOid = $myOid }   # sin SP: usa tu propia identidad

# Conservar la password si ya existe; si no, generar una fuerte (12+ chars, 3 de 4 categorías)
$pw = $null
if (Test-Path $tfvars) {
    $m = Select-String -Path $tfvars -Pattern 'vm_admin_password\s*=\s*"([^"]+)"'
    if ($m) { $pw = $m.Matches[0].Groups[1].Value }
}
if ([string]::IsNullOrWhiteSpace($pw)) {
    $set = 'abcdefghijkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789'.ToCharArray()
    $pw  = (-join (1..20 | ForEach-Object { $set | Get-Random })) + '#Az7'
}

$content = @"
allowed_ssh_cidr      = "$myIp/32"
pipeline_principal_id = "$spOid"
kv_admin_object_id    = "$myOid"
vm_admin_password     = "$pw"
"@
# Escribir SIN BOM (Terraform no acepta BOM al inicio del archivo)
[System.IO.File]::WriteAllText($tfvars, $content, (New-Object System.Text.UTF8Encoding($false)))
Write-Host "    IP SSH permitida: $myIp/32  |  admin Key Vault: $myOid"

# 4-5. Terraform
$env:ARM_SUBSCRIPTION_ID = $SubscriptionId
Push-Location $DevDir
try {
    Step '4/5' 'terraform init...'
    terraform init -reconfigure -input=false | Out-Null
    Step '5/5' 'terraform apply (esto crea los recursos en Azure)...'
    terraform apply -input=false -auto-approve
    Write-Host ''
    Write-Host 'DEV desplegado correctamente.' -ForegroundColor Green
    $ip = terraform output -raw public_ip 2>$null
    if ($ip) {
        Write-Host "IP publica de la VM: $ip"
        Write-Host "SSH:  ssh azureadmin@$ip"
        Write-Host "Password de la VM en: terraform.tfvars (vm_admin_password) y en el Key Vault."
    }
}
finally {
    Pop-Location
}
