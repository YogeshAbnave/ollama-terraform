#!/usr/bin/env pwsh
################################################################################
# Automated Redeploy Script
# This will destroy and recreate with correct security group
################################################################################

$ErrorActionPreference = "Stop"

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "🔧 AUTOMATED REDEPLOY WITH FIX" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "This script will:" -ForegroundColor Yellow
Write-Host "  1. Destroy current deployment (broken security group)" -ForegroundColor White
Write-Host "  2. Wait for AWS cleanup" -ForegroundColor White
Write-Host "  3. Deploy with correct security group" -ForegroundColor White
Write-Host "  4. Show you the new WebUI URL`n" -ForegroundColor White

$confirm = Read-Host "Continue? (y/N)"
if ($confirm -ne "y" -and $confirm -ne "Y") {
    Write-Host "Cancelled." -ForegroundColor Yellow
    exit 0
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Step 1: Destroying Current Deployment" -ForegroundColor Yellow
Write-Host "========================================`n" -ForegroundColor Cyan

terraform destroy -auto-approve

if ($LASTEXITCODE -ne 0) {
    Write-Host "`n❌ Destroy failed!" -ForegroundColor Red
    Write-Host "You may need to manually delete resources in AWS Console." -ForegroundColor Yellow
    exit 1
}

Write-Host "`n✅ Destroy complete!" -ForegroundColor Green

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Step 2: Waiting for AWS Cleanup" -ForegroundColor Yellow
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "Waiting 120 seconds for AWS to clean up resources..." -ForegroundColor Yellow
for ($i = 120; $i -gt 0; $i--) {
    Write-Progress -Activity "Waiting for AWS cleanup" -Status "$i seconds remaining" -PercentComplete ((120 - $i) / 120 * 100)
    Start-Sleep -Seconds 1
}
Write-Progress -Activity "Waiting for AWS cleanup" -Completed

Write-Host "`n✅ Cleanup wait complete!" -ForegroundColor Green

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Step 3: Deploying with Correct Config" -ForegroundColor Yellow
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "Running terraform apply..." -ForegroundColor Yellow
Write-Host "This will create:" -ForegroundColor Cyan
Write-Host "  - Security group with SSH (22), WebUI (8080), Ollama (11434)" -ForegroundColor White
Write-Host "  - EC2 instance with auto-installation" -ForegroundColor White
Write-Host "  - All necessary networking`n" -ForegroundColor White

terraform apply -auto-approve

if ($LASTEXITCODE -ne 0) {
    Write-Host "`n❌ Apply failed!" -ForegroundColor Red
    Write-Host "Check the error messages above." -ForegroundColor Yellow
    exit 1
}

Write-Host "`n✅ Deployment complete!" -ForegroundColor Green

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Step 4: Getting Deployment Info" -ForegroundColor Yellow
Write-Host "========================================`n" -ForegroundColor Cyan

$instanceIP = terraform output -raw instance_public_ip 2>$null
$webuiURL = terraform output -raw webui_url 2>$null
$instanceID = terraform output -raw instance_id 2>$null

if ($instanceIP) {
    Write-Host "✅ Deployment Information:" -ForegroundColor Green
    Write-Host "  Instance ID:  $instanceID" -ForegroundColor White
    Write-Host "  Instance IP:  $instanceIP" -ForegroundColor White
    Write-Host "  WebUI URL:    $webuiURL" -ForegroundColor White
    
    # Save to file
    @"
Deployment completed at: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Instance ID: $instanceID
Instance IP: $instanceIP
WebUI URL: $webuiURL

SSH Command:
ssh -i ollama-key.pem ubuntu@$instanceIP

View Logs:
ssh -i ollama-key.pem ubuntu@$instanceIP 'sudo tail -f /var/log/user-data.log'

Check Status:
ssh -i ollama-key.pem ubuntu@$instanceIP 'cat /home/ubuntu/deployment-status.txt'
"@ | Out-File -FilePath "DEPLOYMENT-INFO.txt" -Encoding UTF8
    
    Write-Host "`n✅ Deployment info saved to DEPLOYMENT-INFO.txt" -ForegroundColor Green
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "⏳ INSTALLATION IN PROGRESS" -ForegroundColor Yellow
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "The EC2 instance is now installing software automatically:" -ForegroundColor White
Write-Host "  1. ✓ System packages updating" -ForegroundColor Cyan
Write-Host "  2. ✓ Git installing" -ForegroundColor Cyan
Write-Host "  3. ⏳ Repository cloning" -ForegroundColor Cyan
Write-Host "  4. ⏳ Ollama installing" -ForegroundColor Cyan
Write-Host "  5. ⏳ Docker installing" -ForegroundColor Cyan
Write-Host "  6. ⏳ AI model downloading (~4.9GB)" -ForegroundColor Cyan
Write-Host "  7. ⏳ Open-WebUI starting" -ForegroundColor Cyan
Write-Host ""
Write-Host "⏱️  Estimated time: 15-20 minutes" -ForegroundColor Yellow
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "📡 MONITORING OPTIONS" -ForegroundColor Yellow
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "Option 1: Wait and access WebUI" -ForegroundColor Cyan
Write-Host "  Wait 20 minutes, then visit: $webuiURL`n" -ForegroundColor White

Write-Host "Option 2: Monitor installation (SSH)" -ForegroundColor Cyan
Write-Host "  ssh -i ollama-key.pem ubuntu@$instanceIP" -ForegroundColor White
Write-Host "  sudo tail -f /var/log/user-data.log`n" -ForegroundColor White

Write-Host "Option 3: Check status later" -ForegroundColor Cyan
Write-Host "  ssh -i ollama-key.pem ubuntu@$instanceIP" -ForegroundColor White
Write-Host "  cat /home/ubuntu/deployment-status.txt`n" -ForegroundColor White

$monitor = Read-Host "Would you like to wait 5 minutes and then test the connection? (y/N)"

if ($monitor -eq "y" -or $monitor -eq "Y") {
    Write-Host "`nWaiting 5 minutes for initial setup..." -ForegroundColor Yellow
    for ($i = 300; $i -gt 0; $i--) {
        Write-Progress -Activity "Waiting for initial setup" -Status "$i seconds remaining" -PercentComplete ((300 - $i) / 300 * 100)
        Start-Sleep -Seconds 1
    }
    Write-Progress -Activity "Waiting for initial setup" -Completed
    
    Write-Host "`nTesting SSH connection..." -ForegroundColor Yellow
    $sshTest = Test-NetConnection -ComputerName $instanceIP -Port 22 -WarningAction SilentlyContinue
    
    if ($sshTest.TcpTestSucceeded) {
        Write-Host "✅ SSH is accessible!" -ForegroundColor Green
        Write-Host "`nYou can now connect:" -ForegroundColor Cyan
        Write-Host "  ssh -i ollama-key.pem ubuntu@$instanceIP`n" -ForegroundColor White
    } else {
        Write-Host "⏳ SSH not ready yet. Wait a few more minutes." -ForegroundColor Yellow
    }
    
    Write-Host "Testing WebUI port..." -ForegroundColor Yellow
    $webuiTest = Test-NetConnection -ComputerName $instanceIP -Port 8080 -WarningAction SilentlyContinue
    
    if ($webuiTest.TcpTestSucceeded) {
        Write-Host "✅ WebUI port is accessible!" -ForegroundColor Green
        Write-Host "`nTry accessing: $webuiURL`n" -ForegroundColor Cyan
    } else {
        Write-Host "⏳ WebUI not ready yet. Installation still in progress." -ForegroundColor Yellow
        Write-Host "   Wait 10-15 more minutes.`n" -ForegroundColor Yellow
    }
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "🎉 REDEPLOY COMPLETE!" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "  1. ⏳ Wait 15-20 minutes for installation" -ForegroundColor White
Write-Host "  2. 🌐 Access WebUI: $webuiURL" -ForegroundColor White
Write-Host "  3. 👤 Register first user (becomes admin)" -ForegroundColor White
Write-Host "  4. 💬 Start chatting with AI!`n" -ForegroundColor White

Write-Host "Useful Commands:" -ForegroundColor Yellow
Write-Host "  SSH:          ssh -i ollama-key.pem ubuntu@$instanceIP" -ForegroundColor White
Write-Host "  View logs:    ssh -i ollama-key.pem ubuntu@$instanceIP 'sudo tail -f /var/log/user-data.log'" -ForegroundColor White
Write-Host "  Check status: ssh -i ollama-key.pem ubuntu@$instanceIP 'cat /home/ubuntu/deployment-status.txt'" -ForegroundColor White
Write-Host "  Test port:    Test-NetConnection -ComputerName $instanceIP -Port 8080`n" -ForegroundColor White

Write-Host "========================================`n" -ForegroundColor Cyan

$openBrowser = Read-Host "Open WebUI in browser now? (Note: May not be ready yet) (y/N)"

if ($openBrowser -eq "y" -or $openBrowser -eq "Y") {
    Write-Host "`nOpening $webuiURL..." -ForegroundColor Cyan
    Start-Process $webuiURL
    Write-Host "If page doesn't load, wait 15-20 minutes and refresh.`n" -ForegroundColor Yellow
}

Write-Host "✨ All done! Your deployment is now correct!" -ForegroundColor Green
Write-Host ""
