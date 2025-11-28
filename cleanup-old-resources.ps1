#!/usr/bin/env pwsh
# Cleanup script to remove old Terraform resources
# Run this before deploying with the new configuration

Write-Host "Cleaning up old Terraform resources..." -ForegroundColor Cyan
Write-Host ""

# Destroy old resources
Write-Host "Running terraform destroy..." -ForegroundColor Yellow
terraform destroy -auto-approve

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "Cleanup complete!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Now you can deploy with the new configuration:" -ForegroundColor Cyan
    Write-Host "  terraform init" -ForegroundColor Yellow
    Write-Host "  terraform apply" -ForegroundColor Yellow
} else {
    Write-Host ""
    Write-Host "Cleanup failed. You may need to manually delete resources in AWS Console." -ForegroundColor Red
    Write-Host ""
    Write-Host "Resources to check:" -ForegroundColor Yellow
    Write-Host "  - VPCs (delete custom VPCs, keep default VPC)"
    Write-Host "  - Internet Gateways"
    Write-Host "  - EC2 Instances"
    Write-Host "  - Elastic IPs"
    Write-Host "  - Security Groups"
}
