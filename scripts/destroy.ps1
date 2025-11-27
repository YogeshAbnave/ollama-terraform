#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Destroy Ollama infrastructure from AWS
.DESCRIPTION
    This script safely destroys the Ollama infrastructure with confirmation prompts
.PARAMETER Force
    Skip confirmation prompts (use with caution!)
.EXAMPLE
    .\destroy.ps1
    .\destroy.ps1 -Force
#>

param(
    [Parameter(Mandatory=$false)]
    [switch]$Force
)

$ErrorActionPreference = "Stop"

Write-Host "🗑️  Ollama Infrastructure Destruction" -ForegroundColor Red
Write-Host ""

# Change to infrastructure directory
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$infraPath = Join-Path (Split-Path -Parent $scriptPath) "infrastructure"
Set-Location $infraPath

# Production safety check
if (-not $Force) {
    Write-Host "⚠️  CRITICAL WARNING: You are about to destroy PRODUCTION infrastructure!" -ForegroundColor Red
    Write-Host "⚠️  This will DELETE all resources including:" -ForegroundColor Red
    Write-Host "   - EC2 instances and Auto Scaling Groups" -ForegroundColor Yellow
    Write-Host "   - Load Balancers" -ForegroundColor Yellow
    Write-Host "   - DynamoDB tables (with all data)" -ForegroundColor Yellow
    Write-Host "   - S3 buckets (with all files)" -ForegroundColor Yellow
    Write-Host "   - CloudFront distributions" -ForegroundColor Yellow
    Write-Host "   - VPC and networking components" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "⚠️  THIS ACTION CANNOT BE UNDONE!" -ForegroundColor Red
    Write-Host ""
    
    $confirmation1 = Read-Host "Type 'DESTROY' to continue"
    if ($confirmation1 -ne "DESTROY") {
        Write-Host "❌ Destruction cancelled." -ForegroundColor Green
        exit 0
    }
    
    Write-Host ""
    $confirmation2 = Read-Host "Are you absolutely sure? Type 'YES' to confirm"
    if ($confirmation2 -ne "YES") {
        Write-Host "❌ Destruction cancelled." -ForegroundColor Green
        exit 0
    }
}

Write-Host ""
Write-Host "🔧 Initializing Terraform..." -ForegroundColor Cyan
terraform init -upgrade

Write-Host ""
Write-Host "🗑️  Destroying infrastructure..." -ForegroundColor Red

try {
    if ($Force) {
        terraform destroy -auto-approve
    } else {
        terraform destroy
    }
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "✅ Infrastructure destroyed successfully!" -ForegroundColor Green
        Write-Host ""
        Write-Host "🧹 Cleanup complete. All resources have been removed." -ForegroundColor Cyan
    } else {
        Write-Host "❌ Destruction failed. Please check the errors above." -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "❌ Destruction failed: $_" -ForegroundColor Red
    exit 1
}
