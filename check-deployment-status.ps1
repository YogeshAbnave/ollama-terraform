#!/usr/bin/env pwsh
# Script to check EC2 deployment status

param(
    [string]$InstanceIP = ""
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  EC2 Deployment Status Checker" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Get instance IP from Terraform if not provided
if ([string]::IsNullOrEmpty($InstanceIP)) {
    Write-Host "Getting instance IP from Terraform..." -ForegroundColor Yellow
    $InstanceIP = terraform output -raw instance_public_ip 2>&1
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Error: Could not get instance IP from Terraform" -ForegroundColor Red
        Write-Host "Please provide IP manually: .\check-deployment-status.ps1 -InstanceIP <your-ip>" -ForegroundColor Yellow
        exit 1
    }
}

Write-Host "Instance IP: $InstanceIP" -ForegroundColor Green
Write-Host ""

# Get SSH key name
$KeyName = terraform output -raw key_name 2>&1
if ($LASTEXITCODE -ne 0) {
    $KeyName = "ollama-webui-key"
}

$KeyFile = "$KeyName.pem"

if (-not (Test-Path $KeyFile)) {
    Write-Host "Error: SSH key file not found: $KeyFile" -ForegroundColor Red
    exit 1
}

Write-Host "Checking deployment status..." -ForegroundColor Cyan
Write-Host ""

# Check if instance is reachable
Write-Host "[1/5] Testing SSH connectivity..." -ForegroundColor Yellow
$sshTest = ssh -i $KeyFile -o ConnectTimeout=5 -o StrictHostKeyChecking=no ubuntu@$InstanceIP "echo 'SSH OK'" 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host "  ✓ SSH connection successful" -ForegroundColor Green
} else {
    Write-Host "  ✗ SSH connection failed" -ForegroundColor Red
    Write-Host "  This might mean:" -ForegroundColor Yellow
    Write-Host "    - Instance is still booting (wait 1-2 minutes)" -ForegroundColor Yellow
    Write-Host "    - Security group doesn't allow SSH from your IP" -ForegroundColor Yellow
    Write-Host "    - Wrong SSH key" -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "[2/5] Checking user-data script status..." -ForegroundColor Yellow
$cloudInitStatus = ssh -i $KeyFile -o StrictHostKeyChecking=no ubuntu@$InstanceIP "cloud-init status" 2>&1

if ($cloudInitStatus -match "done") {
    Write-Host "  ✓ User-data script completed" -ForegroundColor Green
} elseif ($cloudInitStatus -match "running") {
    Write-Host "  ⏳ User-data script still running (this can take 5-10 minutes)" -ForegroundColor Yellow
    Write-Host "  Please wait and try again in a few minutes" -ForegroundColor Yellow
} else {
    Write-Host "  ⚠ User-data status: $cloudInitStatus" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "[3/5] Checking deployment log..." -ForegroundColor Yellow
$logTail = ssh -i $KeyFile -o StrictHostKeyChecking=no ubuntu@$InstanceIP "sudo tail -20 /var/log/user-data.log" 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host "  Last 20 lines of deployment log:" -ForegroundColor Cyan
    Write-Host "  ----------------------------------------" -ForegroundColor Gray
    $logTail | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
    Write-Host "  ----------------------------------------" -ForegroundColor Gray
} else {
    Write-Host "  ✗ Could not read deployment log" -ForegroundColor Red
}

Write-Host ""
Write-Host "[4/5] Checking if Ollama is running..." -ForegroundColor Yellow
$ollamaCheck = ssh -i $KeyFile -o StrictHostKeyChecking=no ubuntu@$InstanceIP "sudo ss -tnlp | grep ollama" 2>&1

if ($LASTEXITCODE -eq 0 -and $ollamaCheck) {
    Write-Host "  ✓ Ollama is running on port 11434" -ForegroundColor Green
} else {
    Write-Host "  ✗ Ollama is not running yet" -ForegroundColor Red
}

Write-Host ""
Write-Host "[5/5] Checking if Open-WebUI container is running..." -ForegroundColor Yellow
$webuiCheck = ssh -i $KeyFile -o StrictHostKeyChecking=no ubuntu@$InstanceIP "sudo docker ps | grep open-webui" 2>&1

if ($LASTEXITCODE -eq 0 -and $webuiCheck) {
    Write-Host "  ✓ Open-WebUI container is running" -ForegroundColor Green
} else {
    Write-Host "  ✗ Open-WebUI container is not running yet" -ForegroundColor Red
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Check deployment status file
$statusFile = ssh -i $KeyFile -o StrictHostKeyChecking=no ubuntu@$InstanceIP "cat /home/ubuntu/deployment-status.txt 2>/dev/null" 2>&1

if ($LASTEXITCODE -eq 0 -and $statusFile) {
    Write-Host ""
    Write-Host "Deployment Status:" -ForegroundColor Green
    $statusFile | ConvertFrom-Json | ConvertTo-Json | Write-Host -ForegroundColor Yellow
} else {
    Write-Host ""
    Write-Host "Deployment status file not found yet." -ForegroundColor Yellow
    Write-Host "Installation is still in progress." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "WebUI URL: http://$InstanceIP:8080" -ForegroundColor Cyan
Write-Host ""
Write-Host "Useful Commands:" -ForegroundColor Cyan
Write-Host "  View full log: ssh -i $KeyFile ubuntu@$InstanceIP 'sudo tail -f /var/log/user-data.log'" -ForegroundColor Yellow
Write-Host "  Check status: ssh -i $KeyFile ubuntu@$InstanceIP 'cat /home/ubuntu/deployment-status.txt'" -ForegroundColor Yellow
Write-Host "  SSH into instance: ssh -i $KeyFile ubuntu@$InstanceIP" -ForegroundColor Yellow
Write-Host ""
