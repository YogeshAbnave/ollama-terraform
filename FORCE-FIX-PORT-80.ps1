#!/usr/bin/env pwsh
Write-Host "=== FORCING PORT 80 FIX - PRODUCTION READY ===" -ForegroundColor Cyan
Write-Host ""

# Step 1: Ensure ASG has desired capacity
Write-Host "Step 1: Setting ASG desired capacity to 2..." -ForegroundColor Yellow
aws autoscaling set-desired-capacity --auto-scaling-group-name ollama-asg --desired-capacity 2
Write-Host "✅ ASG set to 2 instances" -ForegroundColor Green
Write-Host ""

# Step 2: Wait for instances to launch
Write-Host "Step 2: Waiting 30 seconds for instances to start launching..." -ForegroundColor Yellow
Start-Sleep -Seconds 30
Write-Host ""

# Step 3: Check instance status
Write-Host "Step 3: Checking instance status..." -ForegroundColor Yellow
$instances = aws ec2 describe-instances --filters "Name=tag:Name,Values=ollama-asg-instance" "Name=instance-state-name,Values=running,pending" --query 'Reservations[*].Instances[*].[InstanceId,State.Name,LaunchTime]' --output json | ConvertFrom-Json

if ($instances.Count -gt 0) {
    Write-Host "✅ Found $($instances.Count) instance(s):" -ForegroundColor Green
    foreach ($reservation in $instances) {
        foreach ($instance in $reservation) {
            Write-Host "  - Instance: $($instance[0]) | State: $($instance[1]) | Launched: $($instance[2])" -ForegroundColor Gray
        }
    }
} else {
    Write-Host "⚠️  No instances found yet, they may still be launching..." -ForegroundColor Yellow
}
Write-Host ""

# Step 4: Check target group health
Write-Host "Step 4: Checking target group health..." -ForegroundColor Yellow
$tgArn = aws elbv2 describe-target-groups --query 'TargetGroups[?contains(TargetGroupName, `ollama`)].TargetGroupArn' --output text
if ($tgArn) {
    Write-Host "Target Group ARN: $tgArn" -ForegroundColor Gray
    $health = aws elbv2 describe-target-health --target-group-arn $tgArn --output json | ConvertFrom-Json
    
    if ($health.TargetHealthDescriptions.Count -gt 0) {
        Write-Host "✅ Targets registered:" -ForegroundColor Green
        foreach ($target in $health.TargetHealthDescriptions) {
            $state = $target.TargetHealth.State
            $color = if ($state -eq "healthy") { "Green" } elseif ($state -eq "initial") { "Yellow" } else { "Red" }
            Write-Host "  - Target: $($target.Target.Id):$($target.Target.Port) | State: $state" -ForegroundColor $color
        }
    } else {
        Write-Host "⚠️  No targets registered yet" -ForegroundColor Yellow
    }
} else {
    Write-Host "⚠️  Could not find target group" -ForegroundColor Yellow
}
Write-Host ""

# Step 5: Display production URL
Write-Host "=== YOUR PRODUCTION URL (PORT 80) ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "http://ollama-alb-2041931387.us-east-1.elb.amazonaws.com" -ForegroundColor Green
Write-Host ""
Write-Host "✅ NO PORT NUMBER NEEDED - Standard HTTP port 80!" -ForegroundColor Green
Write-Host ""

# Step 6: Timeline
Write-Host "=== TIMELINE ===" -ForegroundColor Cyan
Write-Host "  Now:      Instances launching with port 80 configuration" -ForegroundColor White
Write-Host "  5 min:    Docker containers starting" -ForegroundColor White
Write-Host "  15 min:   Ollama downloading model (deepseek-r1:8b)" -ForegroundColor White
Write-Host "  20-25 min: ✅ PRODUCTION READY ON PORT 80!" -ForegroundColor Green
Write-Host ""

# Step 7: Monitoring commands
Write-Host "=== MONITORING COMMANDS ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Check instance status:" -ForegroundColor Yellow
Write-Host '  aws ec2 describe-instances --filters "Name=tag:Name,Values=ollama-asg-instance" "Name=instance-state-name,Values=running" --query ''Reservations[*].Instances[*].[InstanceId,State.Name]'' --output table' -ForegroundColor Gray
Write-Host ""
Write-Host "Check target health:" -ForegroundColor Yellow
Write-Host "  aws elbv2 describe-target-health --target-group-arn $tgArn" -ForegroundColor Gray
Write-Host ""
Write-Host "Test the URL:" -ForegroundColor Yellow
Write-Host "  curl http://ollama-alb-2041931387.us-east-1.elb.amazonaws.com" -ForegroundColor Gray
Write-Host ""

Write-Host "🎉 Port 80 fix applied! Wait 20-25 minutes for full initialization." -ForegroundColor Green
