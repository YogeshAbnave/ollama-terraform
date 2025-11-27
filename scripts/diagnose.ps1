Write-Host "Diagnosing Ollama Infrastructure..." -ForegroundColor Cyan
Write-Host ""

Write-Host "1. Checking ASG..." -ForegroundColor Yellow
$asg = aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names ollama-asg --output json | ConvertFrom-Json
Write-Host "   Desired: $($asg.AutoScalingGroups[0].DesiredCapacity)"
Write-Host "   Min: $($asg.AutoScalingGroups[0].MinSize)"
Write-Host "   Max: $($asg.AutoScalingGroups[0].MaxSize)"
Write-Host "   Instances: $($asg.AutoScalingGroups[0].Instances.Count)"
Write-Host ""

Write-Host "2. Checking Instances..." -ForegroundColor Yellow
$instances = aws ec2 describe-instances --filters "Name=tag:Name,Values=ollama-asg-instance" --output json | ConvertFrom-Json
$runningInstances = $instances.Reservations.Instances | Where-Object { $_.State.Name -eq "running" }
Write-Host "   Running: $($runningInstances.Count)"
foreach ($inst in $runningInstances) {
    Write-Host "   - $($inst.InstanceId): $($inst.PublicIpAddress)"
}
Write-Host ""

Write-Host "3. Checking Target Health..." -ForegroundColor Yellow
$tgArn = aws elbv2 describe-target-groups --names ollama-tg --query 'TargetGroups[0].TargetGroupArn' --output text
$health = aws elbv2 describe-target-health --target-group-arn $tgArn --output json | ConvertFrom-Json
foreach ($target in $health.TargetHealthDescriptions) {
    Write-Host "   - $($target.Target.Id): $($target.TargetHealth.State) - $($target.TargetHealth.Reason)"
}
Write-Host ""

Write-Host "4. ALB DNS..." -ForegroundColor Yellow
$albDns = aws elbv2 describe-load-balancers --names ollama-alb --query 'LoadBalancers[0].DNSName' --output text
Write-Host "   $albDns"
Write-Host ""

Write-Host "URLs:" -ForegroundColor Green
Write-Host "   http://${albDns}:8080"
