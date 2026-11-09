<#
.SYNOPSIS
  Creates the Azure Storage Account that holds the Terraform remote state.
  Run once, before the first terraform init.
#>
param(
    [string]$Location      = "uksouth",
    [string]$ResourceGroup = "rg-tfstate",
    [string]$Container     = "tfstate"
)

$ErrorActionPreference = "Stop"
$PSNativeCommandUseErrorActionPreference = $true

$StorageAccount = "sttfstate$(Get-Random -Minimum 10000 -Maximum 99999)"

Write-Host "Creating resource group $ResourceGroup..."
az group create --name $ResourceGroup --location $Location --output none

Write-Host "Creating storage account $StorageAccount..."
az storage account create `
    --name $StorageAccount `
    --resource-group $ResourceGroup `
    --location $Location `
    --sku Standard_ZRS `
    --min-tls-version TLS1_2 `
    --allow-blob-public-access false `
    --allow-shared-key-access false `
    --output none

Write-Host "Enabling blob versioning and soft delete..."
az storage account blob-service-properties update `
    --account-name $StorageAccount `
    --resource-group $ResourceGroup `
    --enable-versioning true `
    --enable-delete-retention true `
    --delete-retention-days 14 `
    --output none

Write-Host "Granting data plane access to the signed-in user..."
$StorageId = az storage account show --name $StorageAccount --resource-group $ResourceGroup --query id --output tsv
$UserId    = az ad signed-in-user show --query id --output tsv
az role assignment create `
    --assignee-object-id $UserId `
    --assignee-principal-type User `
    --role "Storage Blob Data Contributor" `
    --scope $StorageId `
    --output none

Write-Host "Waiting 60 seconds for role propagation..."
Start-Sleep -Seconds 60

Write-Host "Creating container $Container..."
az storage container create `
    --name $Container `
    --account-name $StorageAccount `
    --auth-mode login `
    --output none

Write-Host ""
Write-Host "Done. Storage account: $StorageAccount" -ForegroundColor Green