#!/usr/bin/env pwsh
# Quick deployment status checker

Write-Host "Checking deployment status..." -ForegroundColor Cyan
Write-Host ""

# Get instance IP
$IP = terraform output -raw instance_public_ip 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Could not get instance IP" -ForegroundColor Red
    exit 1
}

Write-Host "Instance IP: $IP" -ForegroundColor Green
Write-Host "WebUI URL: http://$IP:8080" -ForegroundColor Cyan
Write-Host ""

# Get key name
$KeyFile = "ollama-webui-key.pem"
if (-not (Test-Path $KeyFile)) {
    Write-Host "Error: Key file not found: $KeyFile" -ForegroundColor Red
    exit 1
}

Write-Host "Testing SSH connection..." -ForegroundColor Yellow
$test = ssh -i $KeyFile -o ConnectTimeout=5 -o StrictHostKeyChecking=no ubuntu@$IP "echo OK" 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Host "SSH connection failed. Instance may still be booting." -ForegroundColor Red
    Write-Host "Wait 1-2 minutes and try again." -ForegroundColor Yellow
    exit 1
}

Write-Host "SSH OK" -ForegroundColor Green
Write-Host ""

Write-Host "Checking cloud-init status..." -ForegroundColor Yellow
ssh -i $KeyFile -o StrictHostKeyChecking=no ubuntu@$IP "cloud-init status"
Write-Host ""

Write-Host "Checking deployment log (last 30 lines)..." -ForegroundColor Yellow
ssh -i $KeyFile -o StrictHostKeyChecking=no ubuntu@$IP "sudo tail -30 /var/log/user-data.log"
Write-Host ""

Write-Host "Checking Ollama..." -ForegroundColor Yellow
ssh -i $KeyFile -o StrictHostKeyChecking=no ubuntu@$IP "sudo ss -tnlp | grep ollama || echo 'Ollama not running yet'"
Write-Host ""

Write-Host "Checking Open-WebUI container..." -ForegroundColor Yellow
ssh -i $KeyFile -o StrictHostKeyChecking=no ubuntu@$IP "sudo docker ps | grep open-webui || echo 'Container not running yet'"
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "If installation is complete, access at:" -ForegroundColor Cyan
Write-Host "http://$IP:8080" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan
