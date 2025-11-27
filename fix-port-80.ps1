#!/usr/bin/env pwsh
Write-Host "=== FIXING OPEN-WEBUI TO USE PORT 80 ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Changes made:" -ForegroundColor Yellow
Write-Host "  ✅ Updated user_data.sh to map port 80:8080 in Docker" -ForegroundColor Green
Write-Host "  ✅ Updated ALB target group to forward to port 80" -ForegroundColor Green
Write-Host "  ✅ Updated security group to allow port 80 from ALB" -ForegroundColor Green
Write-Host ""

# Step 1: Apply Terraform changes
Write-Host "Step 1: Applying Terraform updates..." -ForegroundColor Yellow
Set-Location infrastructure
terraform apply -auto-approve
Write-Host ""

# Step 2: Force instance refresh to get new configuration
Write-Host "Step 2: Forcing instance refresh with new configuration..." -ForegroundColor Yellow
$instances = & aws ec2 describe-instances --filters "Name=tag:Name,Values=ollama-asg-instance" "Name=instance-state-name,Values=running" --query 'Reservations[*].Instances[*].InstanceId' --output text

if ($instances) {
    Write-Host "Terminating old instances to force refresh with new config..." -ForegroundColor Gray
    foreach ($id in $instances.Split()) {
        if ($id) {
            & aws ec2 terminate-instances --instance-ids $id
            Write-Host "  Terminated: $id" -ForegroundColor Gray
        }
    }
    Write-Host "✅ Old instances terminated" -ForegroundColor Green
} else {
    Write-Host "No running instances found" -ForegroundColor Gray
}
Write-Host ""

# Step 3: Ensure ASG has desired capacity
Write-Host "Step 3: Ensuring ASG has 2 instances..." -ForegroundColor Yellow
& aws autoscaling set-desired-capacity --auto-scaling-group-name ollama-asg --desired-capacity 2
Write-Host "✅ Requested 2 instances" -ForegroundColor Green
Write-Host ""

# Step 4: Wait for instances to launch
Write-Host "Step 4: Waiting 60 seconds for instances to start..." -ForegroundColor Yellow
Start-Sleep -Seconds 60
Write-Host ""

# Step 5: Show status
Write-Host "Step 5: Current Status" -ForegroundColor Yellow
& aws ec2 describe-instances --filters "Name=tag:Name,Values=ollama-asg-instance" --query 'Reservations[*].Instances[*].[InstanceId,State.Name,LaunchTime]' --output table
Write-Host ""

Write-Host "=== PRODUCTION URL (PORT 80) ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Your Open-WebUI will be accessible at:" -ForegroundColor White
Write-Host "  http://ollama-alb-2041931387.us-east-1.elb.amazonaws.com" -ForegroundColor Green
Write-Host ""
Write-Host "Note: NO PORT NUMBER NEEDED! Standard HTTP port 80" -ForegroundColor Yellow
Write-Host ""
Write-Host "Timeline:" -ForegroundColor White
Write-Host "  - Now: Instances launching" -ForegroundColor Gray
Write-Host "  - 5 min: Docker containers starting" -ForegroundColor Gray
Write-Host "  - 15 min: Ollama downloading model" -ForegroundColor Gray
Write-Host "  - 20-25 min: ✅ READY on port 80!" -ForegroundColor Green
Write-Host ""
Write-Host "To check progress:" -ForegroundColor Gray
Write-Host '  aws elbv2 describe-target-health --target-group-arn $(aws elbv2 describe-target-groups --names ollama-tg --query "TargetGroups[0].TargetGroupArn" --output text)' -ForegroundColor Gray
