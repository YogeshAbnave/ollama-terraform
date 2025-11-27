#!/usr/bin/env pwsh
Write-Host "🔍 Checking Ollama Infrastructure Status..." -ForegroundColor Cyan
Write-Host ""

# Check ASG
Write-Host "📊 Auto Scaling Group Status:" -ForegroundColor Yellow
$asgInfo = aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names ollama-asg --query 'AutoScalingGroups[0]' | ConvertFrom-Json

Write-Host "  Min Size: $($asgInfo.MinSize)"
Write-Host "  Max Size: $($asgInfo.MaxSize)"
Write-Host "  Desired: $($asgInfo.DesiredCapacity)"
Write-Host "  Current Instances: $($asgInfo.Instances.Count)"
Write-Host ""

# Check instances
Write-Host "🖥️  Instance Status:" -ForegroundColor Yellow
if ($asgInfo.Instances.Count -eq 0) {
    Write-Host "  ❌ No instances running!" -ForegroundColor Red
    Write-Host ""
    Write-Host "  Scaling up ASG..." -ForegroundColor Yellow
    aws autoscaling set-desired-capacity --auto-scaling-group-name ollama-asg --desired-capacity 2
    Write-Host "  ✅ Requested 2 instances. Wait 5-10 minutes for them to start." -ForegroundColor Green
} else {
    foreach ($instance in $asgInfo.Instances) {
        Write-Host "  Instance: $($instance.InstanceId)"
        Write-Host "    Health: $($instance.HealthStatus)"
        Write-Host "    Lifecycle: $($instance.LifecycleState)"
    }
}
Write-Host ""

# Check target health
Write-Host "🎯 Target Group Health:" -ForegroundColor Yellow
$tgArn = aws elbv2 describe-target-groups --names ollama-tg --query 'TargetGroups[0].TargetGroupArn' --output text
$targets = aws elbv2 describe-target-health --target-group-arn $tgArn | ConvertFrom-Json

if ($targets.TargetHealthDescriptions.Count -eq 0) {
    Write-Host "  ❌ No targets registered" -ForegroundColor Red
} else {
    foreach ($target in $targets.TargetHealthDescriptions) {
        Write-Host "  Target: $($target.Target.Id):$($target.Target.Port)"
        Write-Host "    State: $($target.TargetHealth.State)"
        Write-Host "    Reason: $($target.TargetHealth.Reason)"
    }
}
Write-Host ""

# Check ALB
Write-Host "⚖️  Load Balancer:" -ForegroundColor Yellow
$albDns = aws elbv2 describe-load-balancers --names ollama-alb --query 'LoadBalancers[0].DNSName' --output text
Write-Host "  DNS: $albDns"
Write-Host "  Open-WebUI: http://${albDns}:8080"
Write-Host "  Ollama API: http://${albDns}:11434"
Write-Host ""

Write-Host "✅ Status check complete!" -ForegroundColor Green
