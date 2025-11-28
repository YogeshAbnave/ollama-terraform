#!/usr/bin/env pwsh
################################################################################
# Automated Deployment Script
# Push code to GitHub and deploy to AWS in one command
################################################################################

param(
    [string]$CommitMessage = "Update deployment",
    [switch]$SkipGitPush,
    [switch]$DestroyFirst,
    [switch]$SkipVerification
)

$ErrorActionPreference = "Stop"

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "🚀 Automated EC2 Deployment" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Step 1: Verify configuration (unless skipped)
if (-not $SkipVerification) {
    Write-Host "Step 1: Verifying configuration..." -ForegroundColor Yellow
    if (Test-Path "verify-config.ps1") {
        & .\verify-config.ps1
        if ($LASTEXITCODE -ne 0) {
            Write-Host "`n❌ Configuration verification failed!" -ForegroundColor Red
            Write-Host "Fix the issues above and try again." -ForegroundColor Yellow
            exit 1
        }
    } else {
        Write-Host "  ⚠️  verify-config.ps1 not found, skipping verification" -ForegroundColor Yellow
    }
    Write-Host ""
}

# Step 2: Git operations (unless skipped)
if (-not $SkipGitPush) {
    Write-Host "Step 2: Pushing code to GitHub..." -ForegroundColor Yellow
    
    # Check if there are changes to commit
    $gitStatus = git status --porcelain
    
    if ($gitStatus) {
        Write-Host "  📝 Changes detected, committing..." -ForegroundColor Cyan
        
        # Add all changes
        git add .
        
        # Commit with message
        git commit -m $CommitMessage
        
        Write-Host "  ✓ Changes committed" -ForegroundColor Green
    } else {
        Write-Host "  ℹ️  No changes to commit" -ForegroundColor Cyan
    }
    
    # Push to GitHub
    Write-Host "  📤 Pushing to GitHub..." -ForegroundColor Cyan
    git push origin main
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✓ Code pushed successfully" -ForegroundColor Green
    } else {
        Write-Host "  ❌ Git push failed!" -ForegroundColor Red
        Write-Host "  Please check your git configuration and try again." -ForegroundColor Yellow
        exit 1
    }
    
    Write-Host ""
} else {
    Write-Host "Step 2: Skipping git push (--SkipGitPush flag set)" -ForegroundColor Yellow
    Write-Host ""
}

# Step 3: Destroy existing infrastructure (if requested)
if ($DestroyFirst) {
    Write-Host "Step 3: Destroying existing infrastructure..." -ForegroundColor Yellow
    
    terraform destroy -auto-approve
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✓ Infrastructure destroyed" -ForegroundColor Green
        Write-Host "  ⏳ Waiting 30 seconds for AWS cleanup..." -ForegroundColor Cyan
        Start-Sleep -Seconds 30
    } else {
        Write-Host "  ⚠️  Destroy failed or no infrastructure exists" -ForegroundColor Yellow
    }
    
    Write-Host ""
}

# Step 4: Deploy infrastructure
Write-Host "Step 4: Deploying infrastructure to AWS..." -ForegroundColor Yellow
Write-Host "  This will take 2-3 minutes for infrastructure creation" -ForegroundColor Cyan
Write-Host "  Plus 5-8 minutes for software installation" -ForegroundColor Cyan
Write-Host ""

# Run deploy.ps1 if it exists, otherwise run terraform directly
if (Test-Path "deploy.ps1") {
    & .\deploy.ps1
} else {
    # Initialize Terraform
    Write-Host "  🔧 Initializing Terraform..." -ForegroundColor Cyan
    terraform init
    
    # Apply configuration
    Write-Host "  🚀 Applying Terraform configuration..." -ForegroundColor Cyan
    terraform apply -auto-approve
}

if ($LASTEXITCODE -ne 0) {
    Write-Host "`n❌ Deployment failed!" -ForegroundColor Red
    Write-Host "Check the error messages above for details." -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "✅ Infrastructure Deployed Successfully!" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Cyan

# Step 5: Display deployment information
Write-Host "📊 Deployment Information:" -ForegroundColor Yellow
Write-Host ""

# Get outputs
$instanceIP = terraform output -raw instance_public_ip 2>$null
$webuiURL = terraform output -raw webui_url 2>$null
$instanceID = terraform output -raw instance_id 2>$null

if ($instanceIP) {
    Write-Host "  Instance IP:  $instanceIP" -ForegroundColor White
    Write-Host "  Instance ID:  $instanceID" -ForegroundColor White
    Write-Host "  WebUI URL:    $webuiURL" -ForegroundColor White
    Write-Host ""
    
    # Save URL to file
    $webuiURL | Out-File -FilePath "PRODUCTION-URL.txt" -Encoding ASCII
    Write-Host "  ✓ WebUI URL saved to PRODUCTION-URL.txt" -ForegroundColor Green
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "⏳ Installation in Progress" -ForegroundColor Yellow
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "The EC2 instance is now installing software automatically:" -ForegroundColor White
Write-Host "  1. ✓ Updating system packages" -ForegroundColor Cyan
Write-Host "  2. ✓ Installing git" -ForegroundColor Cyan
Write-Host "  3. ⏳ Cloning repository from GitHub" -ForegroundColor Cyan
Write-Host "  4. ⏳ Installing Ollama" -ForegroundColor Cyan
Write-Host "  5. ⏳ Installing Docker" -ForegroundColor Cyan
Write-Host "  6. ⏳ Downloading AI model (~4.9GB)" -ForegroundColor Cyan
Write-Host "  7. ⏳ Starting Open-WebUI container" -ForegroundColor Cyan
Write-Host ""
Write-Host "⏱️  Estimated time: 5-8 minutes" -ForegroundColor Yellow
Write-Host ""

# Step 6: Offer to monitor deployment
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "📡 Monitoring Options" -ForegroundColor Yellow
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "You can monitor the deployment progress:" -ForegroundColor White
Write-Host ""
Write-Host "Option 1: Quick status check" -ForegroundColor Cyan
Write-Host "  .\check-user-data.ps1" -ForegroundColor White
Write-Host ""
Write-Host "Option 2: Watch logs in real-time" -ForegroundColor Cyan
Write-Host "  ssh -i ollama-key.pem ubuntu@$instanceIP 'sudo tail -f /var/log/user-data.log'" -ForegroundColor White
Write-Host ""
Write-Host "Option 3: Wait and check status" -ForegroundColor Cyan
Write-Host "  Start-Sleep -Seconds 600  # Wait 10 minutes" -ForegroundColor White
Write-Host "  .\check-user-data.ps1" -ForegroundColor White
Write-Host ""

# Ask if user wants to monitor
$monitor = Read-Host "Would you like to check deployment status now? (y/N)"

if ($monitor -eq "y" -or $monitor -eq "Y") {
    Write-Host ""
    Write-Host "Waiting 60 seconds for instance to boot..." -ForegroundColor Yellow
    Start-Sleep -Seconds 60
    
    if (Test-Path "check-user-data.ps1") {
        Write-Host ""
        & .\check-user-data.ps1
    } else {
        Write-Host "check-user-data.ps1 not found, connecting via SSH..." -ForegroundColor Yellow
        ssh -i ollama-key.pem -o StrictHostKeyChecking=no ubuntu@$instanceIP 'sudo tail -50 /var/log/user-data.log'
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "🎉 Deployment Complete!" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Wait 5-10 minutes for installation to complete" -ForegroundColor White
Write-Host "  2. Access WebUI at: $webuiURL" -ForegroundColor White
Write-Host "  3. Register first user (becomes admin)" -ForegroundColor White
Write-Host "  4. Start chatting with your AI assistant!" -ForegroundColor White
Write-Host ""

Write-Host "Useful Commands:" -ForegroundColor Yellow
Write-Host "  Check status:  .\check-user-data.ps1" -ForegroundColor White
Write-Host "  View logs:     ssh -i ollama-key.pem ubuntu@$instanceIP 'sudo tail -f /var/log/user-data.log'" -ForegroundColor White
Write-Host "  Get URL:       terraform output webui_url" -ForegroundColor White
Write-Host "  Destroy:       terraform destroy -auto-approve" -ForegroundColor White
Write-Host ""

Write-Host "========================================`n" -ForegroundColor Cyan

# Offer to open browser
$openBrowser = Read-Host "Open WebUI in browser now? (Note: Installation may not be complete yet) (y/N)"

if ($openBrowser -eq "y" -or $openBrowser -eq "Y") {
    Write-Host "Opening $webuiURL in browser..." -ForegroundColor Cyan
    Start-Process $webuiURL
    Write-Host "If the page doesn't load, wait a few minutes and refresh." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "✨ All done! Your AI assistant is deploying!" -ForegroundColor Green
Write-Host ""
