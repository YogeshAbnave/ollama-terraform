#!/usr/bin/env pwsh
Write-Host "🔧 Fixing Ollama ASG..." -ForegroundColor Cyan
Write-Host ""

# Scale up
Write-Host "📈 Scaling up to 2 instances..."
aws autoscaling set-desired-capacity --auto-scaling-group-name ollama-asg --desired-capacity 2

Write-Host "⏳ Waiting 30 seconds..."
Start-Sleep -Seconds 30

# Check status
Write-Host ""
Write-Host "📊 Current status:" -ForegroundColor Yellow
aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names ollama-asg --query 'AutoScalingGroups[0].[DesiredCapacity,Instances[*].[InstanceId,LifecycleState]]'

Write-Host ""
Write-Host "✅ Instances are launching!" -ForegroundColor Green
Write-Host "⏰ Wait 15-25 minutes for full initialization" -ForegroundColor Yellow
Write-Host ""
Write-Host "🌐 Your URLs (will be accessible once healthy):" -ForegroundColor Cyan
Write-Host "   Open-WebUI: http://ollama-alb-2041931387.us-east-1.elb.amazonaws.com:8080" -ForegroundColor White
Write-Host "   Ollama API: http://ollama-alb-2041931387.us-east-1.elb.amazonaws.com:11434" -ForegroundColor White
Write-Host ""
Write-Host "💡 Tip: Run this to check progress:" -ForegroundColor Gray
Write-Host "   aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names ollama-asg" -ForegroundColor Gray
