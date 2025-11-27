#!/usr/bin/env pwsh
Write-Host "=== FIXING OLLAMA INFRASTRUCTURE ===" -ForegroundColor Cyan
Write-Host ""

# Step 1: Apply Terraform changes
Write-Host "Step 1: Applying Terraform updates..." -ForegroundColor Yellow
Set-Location infrastructure
terraform apply -auto-approve
Write-Host ""

# Step 2: Ensure ASG has instances
Write-Host "Step 2: Ensuring ASG has 2 instances..." -ForegroundColor Yellow
& aws autoscaling set-desired-capacity --auto-scaling-group-name ollama-asg --desired-capacity 2
Write-Host "✅ Requested 2 instances" -ForegroundColor Green
Write-Host ""

# Step 3: Terminate any old instances to force refresh
Write-Host "Step 3: Checking for old instances to refresh..." -ForegroundColor Yellow
$instances = & aws ec2 describe-instances --filters "Name=tag:Name,Values=ollama-asg-instance" "Name=instance-state-name,Values=running" --query 'Reservations[*].Instances[*].InstanceId' --output text

if ($instances) {
    Write-Host "Found instances: $instances" -ForegroundColor Gray
    Write-Host "Terminating old instances to get fresh ones with fixes..." -ForegroundColor Yellow
    foreach ($id in $instances.Split()) {
        if ($id) {
            & aws ec2 terminate-instances --instance-ids $id
            Write-Host "  Terminated: $id" -ForegroundColor Gray
        }
    }
    Write-Host "✅ Old instances terminated, new ones will launch" -ForegroundColor Green
} else {
    Write-Host "No running instances found, new ones will launch" -ForegroundColor Gray
}
Write-Host ""

# Step 4: Wait a bit
Write-Host "Step 4: Waiting 60 seconds for new instances to start launching..." -ForegroundColor Yellow
Start-Sleep -Seconds 60
Write-Host ""

# Step 5: Show status
Write-Host "Step 5: Current Status" -ForegroundColor Yellow
Write-Host "Checking instances..." -ForegroundColor Gray
& aws ec2 describe-instances --filters "Name=tag:Name,Values=ollama-asg-instance" --query 'Reservations[*].Instances[*].[InstanceId,State.Name,LaunchTime]' --output table
Write-Host ""

Write-Host "=== NEXT STEPS ===" -ForegroundColor Cyan
Write-Host "1. Wait 20-25 minutes for instances to fully initialize" -ForegroundColor White
Write-Host "2. Ollama will download the model (this takes time)" -ForegroundColor White
Write-Host "3. Access your UI at:" -ForegroundColor White
Write-Host "   http://ollama-alb-2041931387.us-east-1.elb.amazonaws.com" -ForegroundColor Green
Write-Host ""
Write-Host "To check progress, run:" -ForegroundColor Gray
Write-Host '  aws ec2 describe-instances --filters "Name=tag:Name,Values=ollama-asg-instance" "Name=instance-state-name,Values=running" --query ''Reservations[*].Instances[*].[InstanceId,State.Name]'' --output table' -ForegroundColor Gray
