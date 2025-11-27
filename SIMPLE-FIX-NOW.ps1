#!/usr/bin/env pwsh
Write-Host "=== SIMPLE FIX - LAUNCHING INSTANCES NOW ===" -ForegroundColor Cyan
Write-Host ""

Write-Host "Killing old instances and launching fresh ones..." -ForegroundColor Yellow
aws autoscaling set-desired-capacity --auto-scaling-group-name ollama-asg --desired-capacity 0
Start-Sleep -Seconds 30
aws autoscaling set-desired-capacity --auto-scaling-group-name ollama-asg --desired-capacity 2

Write-Host ""
Write-Host "✅ NEW INSTANCES LAUNCHING!" -ForegroundColor Green
Write-Host ""
Write-Host "Your URL: http://ollama-alb-2041931387.us-east-1.elb.amazonaws.com" -ForegroundColor Cyan
Write-Host ""
Write-Host "Wait 5-10 minutes, then check the URL!" -ForegroundColor Yellow
