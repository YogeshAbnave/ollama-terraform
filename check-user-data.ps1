#!/usr/bin/env pwsh
################################################################################
# User Data Execution Checker
# This script helps diagnose if user-data is running on the EC2 instance
################################################################################

param(
    [string]$KeyFile = "ollama-key.pem",
    [string]$InstanceIP = ""
)

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "EC2 User-Data Execution Checker" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Get instance IP from Terraform if not provided
if ([string]::IsNullOrEmpty($InstanceIP)) {
    Write-Host "Getting instance IP from Terraform..." -ForegroundColor Yellow
    $InstanceIP = terraform output -raw instance_public_ip 2>$null
    
    if ([string]::IsNullOrEmpty($InstanceIP)) {
        Write-Host "Error: Could not get instance IP from Terraform" -ForegroundColor Red
        Write-Host "Please provide IP manually: .\check-user-data.ps1 -InstanceIP <your-ip>" -ForegroundColor Yellow
        exit 1
    }
}

Write-Host "Instance IP: $InstanceIP" -ForegroundColor Green
Write-Host "SSH Key: $KeyFile`n" -ForegroundColor Green

# Check if key file exists
if (-not (Test-Path $KeyFile)) {
    Write-Host "Error: SSH key file '$KeyFile' not found" -ForegroundColor Red
    exit 1
}

Write-Host "Connecting to instance and checking user-data execution...`n" -ForegroundColor Yellow

# Create a temporary script to run on the remote instance
$checkScript = @'
#!/bin/bash
echo "=========================================="
echo "User-Data Execution Status"
echo "=========================================="
echo ""

# Check if user-data log exists
if [ -f /var/log/user-data.log ]; then
    echo "✓ User-data log exists"
    echo "  Location: /var/log/user-data.log"
    echo "  Size: $(du -h /var/log/user-data.log | cut -f1)"
    echo ""
    echo "Last 20 lines of user-data log:"
    echo "----------------------------------------"
    tail -20 /var/log/user-data.log
    echo "----------------------------------------"
else
    echo "✗ User-data log NOT found at /var/log/user-data.log"
    echo ""
    echo "Checking cloud-init logs instead:"
    echo "----------------------------------------"
    if [ -f /var/log/cloud-init-output.log ]; then
        tail -20 /var/log/cloud-init-output.log
    else
        echo "No cloud-init logs found either!"
    fi
    echo "----------------------------------------"
fi

echo ""
echo "=========================================="
echo "Deployment Status"
echo "=========================================="
echo ""

# Check deployment status file
if [ -f /home/ubuntu/deployment-status.txt ]; then
    echo "✓ Deployment status file exists"
    cat /home/ubuntu/deployment-status.txt
else
    echo "✗ Deployment status file NOT found"
fi

echo ""
echo "=========================================="
echo "Repository Clone Status"
echo "=========================================="
echo ""

# Check if repository was cloned
if [ -d /home/ubuntu/deployment ]; then
    echo "✓ Repository cloned to /home/ubuntu/deployment"
    echo "  Contents:"
    ls -la /home/ubuntu/deployment/ | head -10
else
    echo "✗ Repository NOT cloned to /home/ubuntu/deployment"
fi

echo ""
echo "=========================================="
echo "Service Status"
echo "=========================================="
echo ""

# Check if Ollama is installed
if command -v ollama &> /dev/null; then
    echo "✓ Ollama is installed"
    ollama --version
else
    echo "✗ Ollama is NOT installed"
fi

echo ""

# Check if Docker is installed
if command -v docker &> /dev/null; then
    echo "✓ Docker is installed"
    docker --version
else
    echo "✗ Docker is NOT installed"
fi

echo ""

# Check if Open-WebUI container is running
if sudo docker ps | grep -q open-webui; then
    echo "✓ Open-WebUI container is running"
    sudo docker ps | grep open-webui
else
    echo "✗ Open-WebUI container is NOT running"
    if sudo docker ps -a | grep -q open-webui; then
        echo "  Container exists but is stopped:"
        sudo docker ps -a | grep open-webui
    fi
fi

echo ""
echo "=========================================="
echo "Cloud-Init Status"
echo "=========================================="
echo ""
cloud-init status --long

echo ""
echo "=========================================="
'@

# Save the script to a temporary file
$tempScript = [System.IO.Path]::GetTempFileName()
$checkScript | Out-File -FilePath $tempScript -Encoding ASCII

try {
    # Copy script to instance and execute
    Write-Host "Uploading diagnostic script..." -ForegroundColor Yellow
    & scp -i $KeyFile -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $tempScript ubuntu@${InstanceIP}:/tmp/check.sh 2>$null
    
    Write-Host "Running diagnostics...`n" -ForegroundColor Yellow
    & ssh -i $KeyFile -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ubuntu@$InstanceIP "chmod +x /tmp/check.sh && /tmp/check.sh"
    
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "Diagnostic Complete" -ForegroundColor Cyan
    Write-Host "========================================`n" -ForegroundColor Cyan
    
    Write-Host "To view full logs in real-time, run:" -ForegroundColor Yellow
    Write-Host "  ssh -i $KeyFile ubuntu@$InstanceIP 'sudo tail -f /var/log/user-data.log'" -ForegroundColor White
    
} catch {
    Write-Host "Error connecting to instance: $_" -ForegroundColor Red
    Write-Host "`nTroubleshooting:" -ForegroundColor Yellow
    Write-Host "  1. Wait a few minutes for instance to fully boot" -ForegroundColor White
    Write-Host "  2. Check security group allows SSH from your IP" -ForegroundColor White
    Write-Host "  3. Verify instance is running: terraform output" -ForegroundColor White
} finally {
    # Clean up temp file
    Remove-Item $tempScript -ErrorAction SilentlyContinue
}
