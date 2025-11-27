#!/usr/bin/env pwsh
Write-Host "=== DIAGNOSING 502 BAD GATEWAY ===" -ForegroundColor Cyan
Write-Host ""

Write-Host "502 Bad Gateway means:" -ForegroundColor Yellow
Write-Host "  - ALB is working ✅" -ForegroundColor Green
Write-Host "  - But backend instances are NOT healthy yet ⏳" -ForegroundColor Yellow
Write-Host ""

# Check 1: ASG Status
Write-Host "Check 1: Auto Scaling Group Status" -ForegroundColor Cyan
Write-Host "----------------------------------------" -ForegroundColor Gray
& aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names ollama-asg --query 'AutoScalingGroups[0].[DesiredCapacity,MinSize,MaxSize]' --output table
Write-Host ""

# Check 2: Instance Status
Write-Host "Check 2: EC2 Instance Status" -ForegroundColor Cyan
Write-Host "----------------------------------------" -ForegroundColor Gray
& aws ec2 describe-instances --filters "Name=tag:Name,Values=ollama-asg-instance" --query 'Reservations[*].Instances[*].[InstanceId,State.Name,LaunchTime]' --output table
Write-Host ""

# Check 3: Target Health
Write-Host "Check 3: Target Group Health" -ForegroundColor Cyan
Write-Host "----------------------------------------" -ForegroundColor Gray
$tgArn = & aws elbv2 describe-target-groups --query 'TargetGroups[?contains(TargetGroupName, `ollama`)].TargetGroupArn' --output text
if ($tgArn) {
    Write-Host "Target Group: $tgArn" -ForegroundColor Gray
    & aws elbv2 describe-target-health --target-group-arn $tgArn --output table
} else {
    Write-Host "⚠️  No target group found" -ForegroundColor Red
}
Write-Host ""

# Check 4: Recent Scaling Activities
Write-Host "Check 4: Recent Scaling Activities" -ForegroundColor Cyan
Write-Host "----------------------------------------" -ForegroundColor Gray
& aws autoscaling describe-scaling-activities --auto-scaling-group-name ollama-asg --max-records 3 --query 'Activities[*].[StartTime,StatusCode,Description]' --output table
Write-Host ""

Write-Host "=== WHAT TO DO ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "If instances are:" -ForegroundColor Yellow
Write-Host "  - 'pending' or 'running' but 'initial' health → WAIT 15-20 more minutes" -ForegroundColor White
Write-Host "  - 'unhealthy' → Check instance logs (see below)" -ForegroundColor White
Write-Host "  - Not showing up → Force launch new instances (see below)" -ForegroundColor White
Write-Host ""

Write-Host "=== FORCE NEW INSTANCES ===" -ForegroundColor Cyan
Write-Host "If no instances or all unhealthy, run:" -ForegroundColor Yellow
Write-Host "  aws autoscaling set-desired-capacity --auto-scaling-group-name ollama-asg --desired-capacity 0" -ForegroundColor Gray
Write-Host "  Start-Sleep -Seconds 30" -ForegroundColor Gray
Write-Host "  aws autoscaling set-desired-capacity --auto-scaling-group-name ollama-asg --desired-capacity 2" -ForegroundColor Gray
Write-Host ""

Write-Host "=== CHECK INSTANCE LOGS ===" -ForegroundColor Cyan
Write-Host "To see what's happening on an instance:" -ForegroundColor Yellow
Write-Host '  $instanceId = (aws ec2 describe-instances --filters "Name=tag:Name,Values=ollama-asg-instance" "Name=instance-state-name,Values=running" --query ''Reservations[0].Instances[0].InstanceId'' --output text)' -ForegroundColor Gray
Write-Host '  aws ec2 get-console-output --instance-id $instanceId --output text' -ForegroundColor Gray
Write-Host ""

Write-Host "🕐 TIMELINE: Instances need 20-25 minutes to become healthy" -ForegroundColor Yellow
Write-Host "   - 0-5 min: Instance launching" -ForegroundColor Gray
Write-Host "   - 5-10 min: Installing Ollama & Docker" -ForegroundColor Gray
Write-Host "   - 10-20 min: Downloading model (deepseek-r1:8b is ~5GB)" -ForegroundColor Gray
Write-Host "   - 20-25 min: ✅ Healthy and ready!" -ForegroundColor Green
