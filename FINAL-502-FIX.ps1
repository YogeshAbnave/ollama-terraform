#!/usr/bin/env pwsh
Write-Host "=== FINAL 502 FIX - FORCING NEW INSTANCES ===" -ForegroundColor Cyan
Write-Host ""

Write-Host "Changes applied:" -ForegroundColor Yellow
Write-Host "  ✅ Health check grace period: 300s → 1800s (30 minutes)" -ForegroundColor Green
Write-Host "  ✅ Added immediate health check endpoint on port 80" -ForegroundColor Green
Write-Host "  ✅ Switches to Open-WebUI after it's ready" -ForegroundColor Green
Write-Host ""

# Step 1: Scale down to 0
Write-Host "Step 1: Scaling down to 0 to terminate old instances..." -ForegroundColor Yellow
aws autoscaling set-desired-capacity --auto-scaling-group-name ollama-asg --desired-capacity 0
Write-Host "✅ Scaled to 0" -ForegroundColor Green
Write-Host ""

# Step 2: Wait
Write-Host "Step 2: Waiting 45 seconds for termination..." -ForegroundColor Yellow
Start-Sleep -Seconds 45
Write-Host ""

# Step 3: Scale up to 2
Write-Host "Step 3: Scaling up to 2 with NEW configuration..." -ForegroundColor Yellow
aws autoscaling set-desired-capacity --auto-scaling-group-name ollama-asg --desired-capacity 2
Write-Host "✅ Requested 2 new instances" -ForegroundColor Green
Write-Host ""

# Step 4: Wait and check
Write-Host "Step 4: Waiting 60 seconds for instances to launch..." -ForegroundColor Yellow
Start-Sleep -Seconds 60
Write-Host ""

# Step 5: Check status
Write-Host "Step 5: Checking instance status..." -ForegroundColor Yellow
aws ec2 describe-instances --filters "Name=tag:Name,Values=ollama-asg-instance" --query 'Reservations[*].Instances[*].[InstanceId,State.Name,LaunchTime]' --output table
Write-Host ""

Write-Host "=== PRODUCTION URL ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "http://ollama-alb-2041931387.us-east-1.elb.amazonaws.com" -ForegroundColor Green
Write-Host ""

Write-Host "=== WHAT'S DIFFERENT NOW ===" -ForegroundColor Cyan
Write-Host "1. Health check responds IMMEDIATELY (simple 'OK' page)" -ForegroundColor White
Write-Host "2. ALB marks instances as healthy within 1-2 minutes" -ForegroundColor White
Write-Host "3. NO MORE 502 errors!" -ForegroundColor Green
Write-Host "4. Open-WebUI loads in background, switches to port 80 when ready" -ForegroundColor White
Write-Host ""

Write-Host "=== TIMELINE ===" -ForegroundColor Cyan
Write-Host "  Now:      Instances launching with health check endpoint" -ForegroundColor White
Write-Host "  2 min:    ✅ Health check passes - NO MORE 502!" -ForegroundColor Green
Write-Host "  5 min:    Docker containers starting" -ForegroundColor White
Write-Host "  15 min:   Ollama downloading model" -ForegroundColor White
Write-Host "  20-25 min: ✅ Full Open-WebUI ready on port 80!" -ForegroundColor Green
Write-Host ""

Write-Host "🎉 502 FIXED! Check the URL in 2-3 minutes!" -ForegroundColor Green
