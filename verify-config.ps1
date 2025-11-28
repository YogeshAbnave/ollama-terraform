#!/usr/bin/env pwsh
################################################################################
# Configuration Verification Script
# Verifies that all required files and configurations are in place
################################################################################

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "EC2 Auto-Deploy Configuration Verification" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$allGood = $true

# Check 1: Terraform installed
Write-Host "Checking Terraform installation..." -ForegroundColor Yellow
if (Get-Command terraform -ErrorAction SilentlyContinue) {
    $tfVersion = terraform version | Select-Object -First 1
    Write-Host "  ✓ Terraform found: $tfVersion" -ForegroundColor Green
} else {
    Write-Host "  ✗ Terraform not found" -ForegroundColor Red
    $allGood = $false
}

# Check 2: AWS CLI installed
Write-Host "`nChecking AWS CLI installation..." -ForegroundColor Yellow
if (Get-Command aws -ErrorAction SilentlyContinue) {
    $awsVersion = aws --version 2>&1
    Write-Host "  ✓ AWS CLI found: $awsVersion" -ForegroundColor Green
} else {
    Write-Host "  ✗ AWS CLI not found" -ForegroundColor Red
    $allGood = $false
}

# Check 3: Required files exist
Write-Host "`nChecking required files..." -ForegroundColor Yellow
$requiredFiles = @(
    "terraform-ec2.tf",
    "terraform.tfvars",
    "user-data.sh.tpl",
    "ec2-deploy-ollama.sh"
)

foreach ($file in $requiredFiles) {
    if (Test-Path $file) {
        Write-Host "  ✓ $file exists" -ForegroundColor Green
    } else {
        Write-Host "  ✗ $file missing" -ForegroundColor Red
        $allGood = $false
    }
}

# Check 4: Git repository URL configured
Write-Host "`nChecking git repository configuration..." -ForegroundColor Yellow
$tfvarsContent = Get-Content "terraform.tfvars" -Raw
if ($tfvarsContent -match 'git_repo_url\s*=\s*"([^"]+)"') {
    $gitUrl = $matches[1]
    if ($gitUrl -match "github.com/YogeshAbnave/ollama-terraform") {
        Write-Host "  ✓ Git repository URL configured: $gitUrl" -ForegroundColor Green
    } elseif ($gitUrl -match "yourusername|your-repo") {
        Write-Host "  ✗ Git repository URL not updated (still placeholder)" -ForegroundColor Red
        $allGood = $false
    } else {
        Write-Host "  ✓ Git repository URL configured: $gitUrl" -ForegroundColor Green
    }
} else {
    Write-Host "  ✗ Git repository URL not found in terraform.tfvars" -ForegroundColor Red
    $allGood = $false
}

# Check 5: SSH key exists
Write-Host "`nChecking SSH key..." -ForegroundColor Yellow
if ($tfvarsContent -match 'key_name\s*=\s*"([^"]+)"') {
    $keyName = $matches[1]
    $keyFile = "$keyName.pem"
    if (Test-Path $keyFile) {
        Write-Host "  ✓ SSH key found: $keyFile" -ForegroundColor Green
    } else {
        Write-Host "  ⚠ SSH key not found: $keyFile (will be created during deployment)" -ForegroundColor Yellow
    }
}

# Check 6: Terraform variables
Write-Host "`nChecking Terraform variables..." -ForegroundColor Yellow
$requiredVars = @("git_repo_url", "git_branch", "default_model")
foreach ($var in $requiredVars) {
    if ($tfvarsContent -match "$var\s*=") {
        Write-Host "  ✓ $var is configured" -ForegroundColor Green
    } else {
        Write-Host "  ✗ $var is missing" -ForegroundColor Red
        $allGood = $false
    }
}

# Check 7: User data template has correct variables
Write-Host "`nChecking user-data template..." -ForegroundColor Yellow
$userDataContent = Get-Content "user-data.sh.tpl" -Raw
$templateVars = @('${git_repo_url}', '${git_branch}', '${default_model}')
foreach ($var in $templateVars) {
    if ($userDataContent -match [regex]::Escape($var)) {
        Write-Host "  ✓ Template variable $var found" -ForegroundColor Green
    } else {
        Write-Host "  ✗ Template variable $var missing" -ForegroundColor Red
        $allGood = $false
    }
}

# Summary
Write-Host "`n========================================" -ForegroundColor Cyan
if ($allGood) {
    Write-Host "✓ All checks passed! Ready to deploy." -ForegroundColor Green
    Write-Host "`nNext steps:" -ForegroundColor Cyan
    Write-Host "  1. Ensure your code is pushed to GitHub" -ForegroundColor White
    Write-Host "  2. Run: .\deploy.ps1" -ForegroundColor White
    Write-Host "  3. Wait 5-10 minutes for deployment" -ForegroundColor White
    Write-Host "  4. Access WebUI at the URL shown in outputs" -ForegroundColor White
} else {
    Write-Host "✗ Some checks failed. Please fix the issues above." -ForegroundColor Red
}
Write-Host "========================================`n" -ForegroundColor Cyan
