<#
.SYNOPSIS
  Creates (or updates) the Entra ID identity used by GitHub Actions via OIDC,
  assigns its roles and stores its IDs as GitHub repository secrets.
  Safe to re-run: existing objects are reused or updated.
#>
param(
    [Parameter(Mandatory)][string]$StorageAccount,
    [string]$StateResourceGroup = "rg-tfstate",
    [string]$AppName            = "gh-azure-multiregion-platform"
)

$ErrorActionPreference = "Stop"
$PSNativeCommandUseErrorActionPreference = $true

$Repo           = gh repo view --json nameWithOwner --jq .nameWithOwner
$SubscriptionId = az account show --query id --output tsv
$TenantId       = az account show --query tenantId --output tsv

# App registration and service principal (reuse if they exist)
$AppId = az ad app list --display-name $AppName --query "[0].appId" --output tsv
if (-not $AppId) {
    Write-Host "Creating app registration $AppName..."
    $AppId = az ad app create --display-name $AppName --query appId --output tsv
}
$SpObjectId = az ad sp list --filter "appId eq '$AppId'" --query "[0].id" --output tsv
if (-not $SpObjectId) {
    Write-Host "Creating service principal..."
    $SpObjectId = az ad sp create --id $AppId --query id --output tsv
}

# GitHub OIDC uses immutable subjects (owner@id/repo@id) for repositories
# created after 18 June 2026, protecting against name-recycling attacks.
$OwnerId = gh api "repos/$Repo" --jq .owner.id
$RepoId  = gh api "repos/$Repo" --jq .id
$Owner, $RepoName = $Repo -split "/"
$Prefix = "repo:${Owner}@${OwnerId}/${RepoName}@${RepoId}"

$Subjects = @{
    "gh-main"           = "${Prefix}:ref:refs/heads/main"
    "gh-pull-request"   = "${Prefix}:pull_request"
    "gh-env-production" = "${Prefix}:environment:production"
}

$Existing = az ad app federated-credential list --id $AppId --query "[].name" --output tsv

foreach ($Name in $Subjects.Keys) {
    $File = New-TemporaryFile
    @{
        name      = $Name
        issuer    = "https://token.actions.githubusercontent.com"
        subject   = $Subjects[$Name]
        audiences = @("api://AzureADTokenExchange")
    } | ConvertTo-Json | Set-Content -Path $File -Encoding utf8

    if ($Existing -contains $Name) {
        Write-Host "Updating federated credential $Name..."
        az ad app federated-credential update --id $AppId --federated-credential-id $Name --parameters "@$File" --output none
    } else {
        Write-Host "Creating federated credential $Name..."
        az ad app federated-credential create --id $AppId --parameters "@$File" --output none
    }
    Remove-Item $File
}

# Role assignments
Write-Host "Assigning roles..."
az role assignment create `
    --assignee-object-id $SpObjectId `
    --assignee-principal-type ServicePrincipal `
    --role Contributor `
    --scope "/subscriptions/$SubscriptionId" `
    --output none

$StorageId = az storage account show --name $StorageAccount --resource-group $StateResourceGroup --query id --output tsv
az role assignment create `
    --assignee-object-id $SpObjectId `
    --assignee-principal-type ServicePrincipal `
    --role "Storage Blob Data Contributor" `
    --scope $StorageId `
    --output none

# GitHub environment and secrets
Write-Host "Creating GitHub environment 'production'..."
gh api --method PUT "repos/$Repo/environments/production" --silent

Write-Host "Saving IDs as GitHub secrets..."
gh secret set AZURE_CLIENT_ID       --body $AppId
gh secret set AZURE_TENANT_ID       --body $TenantId
gh secret set AZURE_SUBSCRIPTION_ID --body $SubscriptionId

Write-Host ""
Write-Host "Done. Client ID: $AppId" -ForegroundColor Green