<#
.SYNOPSIS
    Destruye el entorno DEV de azure-iac-portfolio en Azure (para dejar de gastar crédito).

.DESCRIPTION
    Ejecuta 'terraform destroy' del entorno dev. NO borra el backend remoto (rg-tfstate),
    que es gratis y permite relanzar con deploy-dev.ps1. El estado queda vacío en el backend.

.EXAMPLE
    .\scripts\destroy-dev.ps1
#>

$ErrorActionPreference = 'Stop'

$SubscriptionId = 'ed313ee9-11b5-45d4-ac7c-6116fc894139'
$TenantId       = '952b5ee7-d646-4665-bcda-c47226bc38e5'
$DevDir         = Join-Path $PSScriptRoot '..\terraform\environments\dev'

$acc = az account show -o json 2>$null | ConvertFrom-Json
if (-not $acc) {
    Write-Host "No hay sesión activa. Inicia con: az login --tenant $TenantId" -ForegroundColor Yellow
    exit 1
}
az account set --subscription $SubscriptionId | Out-Null
Write-Host "Cuenta: $($acc.user.name)  |  Suscripción: $SubscriptionId"

$env:ARM_SUBSCRIPTION_ID = $SubscriptionId
Push-Location $DevDir
try {
    Write-Host "==> terraform destroy (elimina la VM, IP, Key Vault, Storage, red)..." -ForegroundColor Cyan
    terraform destroy -input=false -auto-approve
    Write-Host ''
    Write-Host 'DEV destruido. Ya no consume crédito. Relanza cuando quieras con: .\scripts\deploy-dev.ps1' -ForegroundColor Green
}
finally {
    Pop-Location
}
