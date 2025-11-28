#!/usr/bin/env pwsh
# Script to create default VPC if it doesn't exist

Write-Host "Checking for default VPC..." -ForegroundColor Cyan

# Check if default VPC exists
$defaultVpc = aws ec2 describe-vpcs --filters "Name=isDefault,Values=true" --query "Vpcs[0].VpcId" --output text 2>&1

if ($defaultVpc -match "vpc-") {
    Write-Host "Default VPC already exists: $defaultVpc" -ForegroundColor Green
} else {
    Write-Host "No default VPC found. Creating one..." -ForegroundColor Yellow
    
    # Create default VPC
    $result = aws ec2 create-default-vpc --output json 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        $vpcId = ($result | ConvertFrom-Json).Vpc.VpcId
        Write-Host "Default VPC created successfully: $vpcId" -ForegroundColor Green
    } else {
        Write-Host "Failed to create default VPC" -ForegroundColor Red
        Write-Host $result -ForegroundColor Red
        exit 1
    }
}

Write-Host ""
Write-Host "Ready to deploy! Run:" -ForegroundColor Cyan
Write-Host "  terraform init" -ForegroundColor Yellow
Write-Host "  terraform apply" -ForegroundColor Yellow
