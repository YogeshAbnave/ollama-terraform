#!/usr/bin/env pwsh
# One-Command Deployment Script for Ollama + Open-WebUI on AWS EC2
# Usage: .\deploy.ps1

param(
    [string]$Region = "us-east-1",
    [string]$InstanceType = "t3.xlarge",
    [int]$StorageSize = 50,
    [string]$ProjectName = "ollama-webui"
)

# Color output functions
function Write-Success { Write-Host "SUCCESS: $args" -ForegroundColor Green }
function Write-Info { Write-Host "INFO: $args" -ForegroundColor Cyan }
function Write-Error { Write-Host "ERROR: $args" -ForegroundColor Red }
function Write-Warning { Write-Host "WARNING: $args" -ForegroundColor Yellow }

# Clear screen for clean output
Clear-Host

Write-Info "Starting One-Command Deployment..."
Write-Host ""

# Check prerequisites
Write-Info "Checking prerequisites..."

# Check Terraform
try {
    $null = terraform version 2>&1
    Write-Success "Terraform installed"
} catch {
    Write-Error "Terraform not found. Install with: choco install terraform"
    exit 1
}

# Check AWS CLI
try {
    $null = aws --version 2>&1
    Write-Success "AWS CLI installed"
} catch {
    Write-Error "AWS CLI not found. Install with: choco install awscli"
    exit 1
}

# Check AWS credentials
$awsCheck = aws sts get-caller-identity 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Success "AWS credentials configured"
} else {
    Write-Error "AWS credentials not configured. Run: aws configure"
    exit 1
}

Write-Host ""
Write-Info "Getting your IP address..."
$MyIP = Invoke-RestMethod -Uri 'https://api.ipify.org?format=text'
Write-Success "Your IP: $MyIP"

Write-Host ""
Write-Info "Setting up SSH key..."

# Key pair setup
$KeyName = "$ProjectName-key"
$KeyFile = "$KeyName.pem"

if (Test-Path $KeyFile) {
    Write-Success "Key file already exists: $KeyFile"
} else {
    Write-Info "Creating new key pair..."
    # Use AWS CLI to create key pair
    $keyMaterial = aws ec2 create-key-pair --key-name $KeyName --query 'KeyMaterial' --output text --region $Region 2>&1
    if ($LASTEXITCODE -eq 0) {
        $keyMaterial | Out-File -FilePath $KeyFile -Encoding ASCII -NoNewline
        Write-Success "Key pair created: $KeyFile"
    } else {
        Write-Warning "Key pair might already exist in AWS"
    }
}

Write-Host ""
Write-Info "Creating terraform.tfvars..."

# Create terraform.tfvars
$tfvarsContent = "# Auto-generated configuration`n"
$tfvarsContent += "aws_region       = `"$Region`"`n"
$tfvarsContent += "instance_type    = `"$InstanceType`"`n"
$tfvarsContent += "storage_size     = $StorageSize`n"
$tfvarsContent += "key_name         = `"$KeyName`"`n"
$tfvarsContent += "allowed_ssh_cidr = `"$MyIP/32`"`n"
$tfvarsContent += "project_name     = `"$ProjectName`"`n"
$tfvarsContent += "default_model    = `"1`"`n"

$tfvarsContent | Out-File -FilePath "terraform.tfvars" -Encoding UTF8
Write-Success "Configuration created"

Write-Host ""
Write-Info "Initializing Terraform..."
terraform init -input=false | Out-Null
Write-Success "Terraform initialized"

Write-Host ""
Write-Info "Deploying infrastructure..."
Write-Info "This will take 2-3 minutes..."
Write-Host ""

# Deploy with Terraform
terraform apply -auto-approve

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Success "Deployment completed successfully!"
    Write-Host ""
    
    # Get the WebUI URL
    $webuiUrl = terraform output -raw webui_url 2>&1
    
    if ($webuiUrl -match "http") {
        Write-Host "============================================================" -ForegroundColor Green
        Write-Host ""
        Write-Host "  YOUR AI ASSISTANT IS DEPLOYING!" -ForegroundColor Green
        Write-Host ""
        Write-Host "  Production URL:" -ForegroundColor Cyan
        Write-Host "  $webuiUrl" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "============================================================" -ForegroundColor Green
        Write-Host ""
        Write-Info "Installation in progress (5-10 minutes)"
        Write-Info "First user to register becomes admin"
        Write-Host ""
        
        # Save to file
        $webuiUrl | Out-File -FilePath "PRODUCTION-URL.txt" -Encoding UTF8
        Write-Success "URL saved to: PRODUCTION-URL.txt"
        
        # Copy URL to clipboard if possible
        try {
            $webuiUrl | Set-Clipboard
            Write-Success "URL copied to clipboard!"
        } catch {
            Write-Warning "Could not copy to clipboard (clipboard not available)"
        }
        
        # Display deployment status commands
        Write-Host ""
        Write-Info "Deployment Status Commands:"
        $logCmd = terraform output -raw deployment_log_command 2>&1
        $statusCmd = terraform output -raw deployment_status_command 2>&1
        if ($logCmd -notmatch "error") {
            Write-Host "  View logs: " -NoNewline
            Write-Host "$logCmd" -ForegroundColor Yellow
        }
        if ($statusCmd -notmatch "error") {
            Write-Host "  Check status: " -NoNewline
            Write-Host "$statusCmd" -ForegroundColor Yellow
        }
        
        Write-Host ""
        Write-Info "Opening browser in 3 seconds..."
        Start-Sleep -Seconds 3
        Start-Process $webuiUrl
        
    } else {
        Write-Warning "Could not retrieve URL. Run: terraform output webui_url"
    }
    
} else {
    Write-Host ""
    Write-Error "Deployment failed!"
    Write-Host ""
    exit 1
}

Write-Host ""
Write-Info "Deployment complete!"
Write-Host ""
