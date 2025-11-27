#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Deploy Ollama infrastructure to AWS
.DESCRIPTION
    This script deploys the Ollama production infrastructure using Terraform
.PARAMETER AutoApprove
    Skip interactive approval of Terraform plan
.EXAMPLE
    .\deploy.ps1
    .\deploy.ps1 -AutoApprove
#>

param(
    [Parameter(Mandatory=$false)]
    [switch]$AutoApprove
)

$ErrorActionPreference = "Stop"

Write-Host "Ollama Infrastructure Deployment" -ForegroundColor Cyan
Write-Host ""

# Change to infrastructure directory
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$infraPath = Join-Path (Split-Path -Parent $scriptPath) "infrastructure"
Set-Location $infraPath

Write-Host "Working directory: $infraPath" -ForegroundColor Gray
Write-Host ""

# Step 1: Validate prerequisites
Write-Host "Step 1: Validating prerequisites..." -ForegroundColor Cyan

# Check AWS CLI
try {
    $awsVersion = aws --version 2>&1
    Write-Host "[OK] AWS CLI: $awsVersion" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] AWS CLI not found. Please install AWS CLI first." -ForegroundColor Red
    Write-Host "   Download from: https://aws.amazon.com/cli/" -ForegroundColor Yellow
    exit 1
}

# Check Terraform
try {
    $tfVersion = terraform version -json | ConvertFrom-Json
    Write-Host "[OK] Terraform: v$($tfVersion.terraform_version)" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Terraform not found. Please install Terraform first." -ForegroundColor Red
    Write-Host "   Download from: https://www.terraform.io/downloads" -ForegroundColor Yellow
    exit 1
}

# Check AWS credentials
try {
    $awsIdentity = aws sts get-caller-identity 2>&1 | ConvertFrom-Json
    Write-Host "[OK] AWS Account: $($awsIdentity.Account)" -ForegroundColor Green
    Write-Host "   User/Role: $($awsIdentity.Arn)" -ForegroundColor Gray
} catch {
    Write-Host "[ERROR] AWS credentials not configured. Please run 'aws configure' first." -ForegroundColor Red
    exit 1
}

Write-Host ""

# Step 2: Production confirmation
Write-Host "WARNING: You are deploying to PRODUCTION!" -ForegroundColor Yellow
Write-Host ""
$confirmation = Read-Host "Type 'DEPLOY' to confirm"
if ($confirmation -ne "DEPLOY") {
    Write-Host "[CANCELLED] Deployment cancelled." -ForegroundColor Red
    exit 1
}
Write-Host ""

# Step 3: Initialize Terraform
Write-Host "Step 2: Initializing Terraform..." -ForegroundColor Cyan
try {
    terraform init -upgrade
    if ($LASTEXITCODE -ne 0) { throw "Terraform init failed" }
    Write-Host "[OK] Terraform initialized successfully" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Terraform initialization failed: $_" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Step 4: Validate Terraform configuration
Write-Host "Step 3: Validating Terraform configuration..." -ForegroundColor Cyan
try {
    terraform validate
    if ($LASTEXITCODE -ne 0) { throw "Terraform validation failed" }
    Write-Host "[OK] Terraform configuration is valid" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Terraform validation failed: $_" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Step 5: Format check
Write-Host "Step 4: Checking Terraform formatting..." -ForegroundColor Cyan
$formatCheck = terraform fmt -check -recursive
if ($LASTEXITCODE -ne 0) {
    Write-Host "[INFO] Terraform files are not properly formatted. Running formatter..." -ForegroundColor Yellow
    terraform fmt -recursive
    Write-Host "[OK] Files formatted" -ForegroundColor Green
} else {
    Write-Host "[OK] All files are properly formatted" -ForegroundColor Green
}
Write-Host ""

# Step 6: Plan
Write-Host "Step 5: Creating Terraform plan..." -ForegroundColor Cyan
try {
    terraform plan -out=tfplan
    if ($LASTEXITCODE -ne 0) { throw "Terraform plan failed" }
    Write-Host "[OK] Terraform plan created successfully" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Terraform plan failed: $_" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Step 7: Apply
if (-not $AutoApprove) {
    Write-Host "Review the plan above carefully." -ForegroundColor Yellow
    $applyConfirm = Read-Host "Do you want to apply this plan? (yes/no)"
    if ($applyConfirm -ne "yes") {
        Write-Host "[CANCELLED] Deployment cancelled." -ForegroundColor Red
        Remove-Item "tfplan" -ErrorAction SilentlyContinue
        exit 1
    }
}

Write-Host ""
Write-Host "Step 6: Applying Terraform plan..." -ForegroundColor Cyan
try {
    terraform apply "tfplan"
    if ($LASTEXITCODE -ne 0) { throw "Terraform apply failed" }
    Write-Host "[OK] Infrastructure deployed successfully!" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Terraform apply failed: $_" -ForegroundColor Red
    exit 1
} finally {
    Remove-Item "tfplan" -ErrorAction SilentlyContinue
}
Write-Host ""

# Step 8: Get outputs
Write-Host "Step 7: Retrieving deployment information..." -ForegroundColor Cyan
Write-Host ""
Write-Host "=== Ollama Infrastructure Endpoints ===" -ForegroundColor Cyan
Write-Host ""

$outputs = terraform output -json | ConvertFrom-Json

if ($outputs.ollama_open_webui_url) {
    Write-Host "Open-WebUI URL:" -ForegroundColor Green
    Write-Host "   $($outputs.ollama_open_webui_url.value)" -ForegroundColor White
    Write-Host ""
}

if ($outputs.ollama_api_url) {
    Write-Host "Ollama API URL:" -ForegroundColor Green
    Write-Host "   $($outputs.ollama_api_url.value)" -ForegroundColor White
    Write-Host ""
}

if ($outputs.ollama_alb_dns_name) {
    Write-Host "Load Balancer DNS:" -ForegroundColor Green
    Write-Host "   $($outputs.ollama_alb_dns_name.value)" -ForegroundColor White
    Write-Host ""
}

if ($outputs.ollama_ssh_key_path) {
    Write-Host "SSH Key Path:" -ForegroundColor Green
    Write-Host "   $($outputs.ollama_ssh_key_path.value)" -ForegroundColor White
    Write-Host ""
}

Write-Host "=== Next Steps ===" -ForegroundColor Cyan
Write-Host "1. Wait 5-10 minutes for instances to fully initialize" -ForegroundColor Yellow
Write-Host "2. Access Open-WebUI at the URL above" -ForegroundColor Yellow
Write-Host "3. Monitor: aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names ollama-asg" -ForegroundColor Yellow
Write-Host ""
Write-Host "[SUCCESS] Deployment completed successfully!" -ForegroundColor Green
