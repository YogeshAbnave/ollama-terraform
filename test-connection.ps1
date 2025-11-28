#!/usr/bin/env pwsh
# Simple connection test for 52.54.170.140:8080

$IP = "52.54.170.140"

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Testing Connection to $IP`:8080" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Test SSH (port 22)
Write-Host "Testing SSH (port 22)..." -ForegroundColor Yellow
$ssh = Test-NetConnection -ComputerName $IP -Port 22 -WarningAction SilentlyContinue
if ($ssh.TcpTestSucceeded) {
    Write-Host "✅ SSH port 22 is OPEN" -ForegroundColor Green
} else {
    Write-Host "❌ SSH port 22 is CLOSED" -ForegroundColor Red
}

# Test WebUI (port 8080)
Write-Host "`nTesting WebUI (port 8080)..." -ForegroundColor Yellow
$webui = Test-NetConnection -ComputerName $IP -Port 8080 -WarningAction SilentlyContinue
if ($webui.TcpTestSucceeded) {
    Write-Host "✅ Port 8080 is OPEN" -ForegroundColor Green
} else {
    Write-Host "❌ Port 8080 is CLOSED" -ForegroundColor Red
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "DIAGNOSIS" -ForegroundColor Yellow
Write-Host "========================================`n" -ForegroundColor Cyan

if (-not $webui.TcpTestSucceeded) {
    Write-Host "🔴 Port 8080 is NOT accessible!" -ForegroundColor Red
    Write-Host "`nThis means either:" -ForegroundColor Yellow
    Write-Host "  1. Security group blocks port 8080" -ForegroundColor White
    Write-Host "  2. Open-WebUI container is not running" -ForegroundColor White
    Write-Host "  3. Installation is still in progress`n" -ForegroundColor White
    
    if ($ssh.TcpTestSucceeded) {
        Write-Host "✅ SSH works! You can connect and fix it:" -ForegroundColor Green
        Write-Host "`nRun these commands:" -ForegroundColor Cyan
        Write-Host "  ssh -i ollama-key.pem ubuntu@$IP" -ForegroundColor White
        Write-Host "  sudo docker ps" -ForegroundColor White
        Write-Host "  sudo ss -tnlp | grep 8080" -ForegroundColor White
        Write-Host "`nIf nothing is running, run the fix:" -ForegroundColor Cyan
        Write-Host "  curl -sSL https://raw.githubusercontent.com/YogeshAbnave/ollama-terraform/main/fix-deployment.sh | sudo bash`n" -ForegroundColor White
    } else {
        Write-Host "❌ SSH is also blocked! Security group issue!" -ForegroundColor Red
        Write-Host "`nYou need to redeploy with correct security group:" -ForegroundColor Yellow
        Write-Host "  terraform destroy -auto-approve" -ForegroundColor White
        Write-Host "  Start-Sleep -Seconds 120" -ForegroundColor White
        Write-Host "  terraform apply -auto-approve`n" -ForegroundColor White
    }
} else {
    Write-Host "✅ Port 8080 is accessible!" -ForegroundColor Green
    Write-Host "`nTry accessing in browser:" -ForegroundColor Cyan
    Write-Host "  http://$IP`:8080`n" -ForegroundColor White
}

Write-Host "========================================`n" -ForegroundColor Cyan
