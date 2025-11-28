#!/usr/bin/env pwsh
################################################################################
# Connection Diagnostic Script
# Diagnose why you can't connect to 52.54.170.140:8080
################################################################################

$IP = "52.54.170.140"
$ErrorActionPreference = "Continue"

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "🔍 CONNECTION DIAGNOSTIC" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "Target: $IP`:8080`n" -ForegroundColor Yellow

# Test 1: Ping
Write-Host "Test 1: Ping Instance" -ForegroundColor Yellow
Write-Host "-----------------------------------"
$ping = Test-Connection -ComputerName $IP -Count 2 -Quiet
if ($ping) {
    Write-Host "✅ Instance is reachable via ping" -ForegroundColor Green
} else {
    Write-Host "❌ Cannot ping instance (might be blocked by security group)" -ForegroundColor Red
}

# Test 2: Port 22 (SSH)
Write-Host "`nTest 2: SSH Port (22)" -ForegroundColor Yellow
Write-Host "-----------------------------------"
$ssh = Test-NetConnection -ComputerName $IP -Port 22 -WarningAction SilentlyContinue
if ($ssh.TcpTestSucceeded) {
    Write-Host "✅ SSH port 22 is open" -ForegroundColor Green
} else {
    Write-Host "❌ SSH port 22 is closed or blocked" -ForegroundColor Red
}

# Test 3: Port 8080 (WebUI)
Write-Host "`nTest 3: WebUI Port (8080)" -ForegroundColor Yellow
Write-Host "-----------------------------------"
$webui = Test-NetConnection -ComputerName $IP -Port 8080 -WarningAction SilentlyContinue
if ($webui.TcpTestSucceeded) {
    Write-Host "✅ Port 8080 is open and listening!" -ForegroundColor Green
    Write-Host "   But connection times out? Check if service is responding..." -ForegroundColor Yellow
} else {
    Write-Host "❌ Port 8080 is NOT open!" -ForegroundColor Red
    Write-Host "   This is the problem!" -ForegroundColor Red
}

# Test 4: Try HTTP request
Write-Host "`nTest 4: HTTP Request" -ForegroundColor Yellow
Write-Host "-----------------------------------"
try {
    $response = Invoke-WebRequest -Uri "http://$IP`:8080" -TimeoutSec 5 -ErrorAction Stop
    Write-Host "✅ WebUI is responding!" -ForegroundColor Green
    Write-Host "   Status: $($response.StatusCode)" -ForegroundColor Green
} catch {
    Write-Host "❌ WebUI is not responding" -ForegroundColor Red
    Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "DIAGNOSIS" -ForegroundColor Yellow
Write-Host "========================================`n" -ForegroundColor Cyan

if (-not $webui.TcpTestSucceeded) {
    Write-Host "🔴 PROBLEM IDENTIFIED: Port 8080 is NOT accessible" -ForegroundColor Red
    Write-Host "`nPossible causes:" -ForegroundColor Yellow
    Write-Host "  1. Security group doesn't allow port 8080" -ForegroundColor White
    Write-Host "  2. Open-WebUI container is not running" -ForegroundColor White
    Write-Host "  3. Container is running but not bound to port 8080" -ForegroundColor White
    Write-Host "  4. Installation is still in progress" -ForegroundColor White
    
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "SOLUTIONS" -ForegroundColor Yellow
    Write-Host "========================================`n" -ForegroundColor Cyan
    
    Write-Host "Solution 1: Check Security Group" -ForegroundColor Cyan
    Write-Host "-----------------------------------"
    Write-Host "Run this command:" -ForegroundColor Yellow
    Write-Host "  terraform output security_group_id" -ForegroundColor White
    Write-Host "`nThen check in AWS Console:" -ForegroundColor Yellow
    Write-Host "  EC2 → Security Groups → Your SG → Inbound Rules" -ForegroundColor White
    Write-Host "  Should have: TCP 8080 from 0.0.0.0/0" -ForegroundColor White
    
    Write-Host "`nSolution 2: SSH In and Check Services" -ForegroundColor Cyan
    Write-Host "-----------------------------------"
    if ($ssh.TcpTestSucceeded) {
        Write-Host "SSH is working! Connect and check:" -ForegroundColor Green
        Write-Host "  ssh -i ollama-key.pem ubuntu@$IP" -ForegroundColor White
        Write-Host "`nThen run:" -ForegroundColor Yellow
        Write-Host "  sudo docker ps | grep open-webui" -ForegroundColor White
        Write-Host "  sudo ss -tnlp | grep 8080" -ForegroundColor White
        Write-Host "  sudo tail -f /var/log/user-data.log" -ForegroundColor White
    } else {
        Write-Host "❌ SSH is also blocked! Security group issue!" -ForegroundColor Red
        Write-Host "Fix security group first!" -ForegroundColor Yellow
    }
    
    Write-Host "`nSolution 3: Run Fix Script" -ForegroundColor Cyan
    Write-Host "-----------------------------------"
    Write-Host "If you can SSH in, run:" -ForegroundColor Yellow
    Write-Host "  ssh -i ollama-key.pem ubuntu@$IP" -ForegroundColor White
    Write-Host "  curl -sSL https://raw.githubusercontent.com/YogeshAbnave/ollama-terraform/main/fix-deployment.sh | sudo bash" -ForegroundColor White
    
    Write-Host "`nSolution 4: Wait Longer" -ForegroundColor Cyan
    Write-Host "-----------------------------------"
    Write-Host "Installation takes 15-20 minutes total." -ForegroundColor Yellow
    Write-Host "How long has it been since deployment?" -ForegroundColor Yellow
    Write-Host "If less than 20 minutes, wait and try again." -ForegroundColor White
    
} else {
    Write-Host "🟡 Port 8080 is open but service not responding" -ForegroundColor Yellow
    Write-Host "`nThis means:" -ForegroundColor Yellow
    Write-Host "  - Security group is correct ✅" -ForegroundColor Green
    Write-Host "  - But container is not running or not responding ❌" -ForegroundColor Red
    
    Write-Host "`nSSH in and run fix script:" -ForegroundColor Cyan
    Write-Host "  ssh -i ollama-key.pem ubuntu@$IP" -ForegroundColor White
    Write-Host "  curl -sSL https://raw.githubusercontent.com/YogeshAbnave/ollama-terraform/main/fix-deployment.sh | sudo bash" -ForegroundColor White
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "QUICK FIX COMMANDS" -ForegroundColor Yellow
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "# 1. Check security group" -ForegroundColor Cyan
Write-Host "terraform output security_group_id" -ForegroundColor White
Write-Host "aws ec2 describe-security-groups --group-ids <sg-id>" -ForegroundColor White

Write-Host "`n# 2. SSH and check" -ForegroundColor Cyan
Write-Host "ssh -i ollama-key.pem ubuntu@$IP" -ForegroundColor White
Write-Host "sudo docker ps" -ForegroundColor White
Write-Host "sudo ss -tnlp | grep 8080" -ForegroundColor White

Write-Host "`n# 3. Run fix" -ForegroundColor Cyan
Write-Host "ssh -i ollama-key.pem ubuntu@$IP" -ForegroundColor White
Write-Host "curl -sSL https://raw.githubusercontent.com/YogeshAbnave/ollama-terraform/main/fix-deployment.sh | sudo bash" -ForegroundColor White

Write-Host "`n# 4. Or redeploy" -ForegroundColor Cyan
Write-Host "terraform destroy -auto-approve && terraform apply -auto-approve" -ForegroundColor White

Write-Host "`n========================================`n" -ForegroundColor Cyan

# Offer to try SSH
if ($ssh.TcpTestSucceeded) {
    $trySsh = Read-Host "SSH is working. Try connecting now? (y/N)"
    if ($trySsh -eq "y" -or $trySsh -eq "Y") {
        Write-Host "`nConnecting via SSH..." -ForegroundColor Cyan
        Write-Host "Once connected, run: sudo docker ps`n" -ForegroundColor Yellow
        & ssh -i ollama-key.pem ubuntu@$IP
    }
}

Write-Host ""
