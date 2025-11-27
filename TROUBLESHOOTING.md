# Troubleshooting Guide

## Issue: Cannot Access Open-WebUI (Connection Timeout)

### Problem
The URL `http://ollama-alb-2041931387.us-east-1.elb.amazonaws.com:8080` times out.

### Root Cause
The Auto Scaling Group has **0 running instances**.

### Solution

Run these commands to fix:

```powershell
# 1. Set desired capacity to 2 instances
aws autoscaling set-desired-capacity `
  --auto-scaling-group-name ollama-asg `
  --desired-capacity 2

# 2. Wait 5-10 minutes for instances to launch

# 3. Check instance status
aws ec2 describe-instances `
  --filters "Name=tag:Name,Values=ollama-asg-instance" "Name=instance-state-name,Values=running,pending" `
  --query 'Reservations[*].Instances[*].[InstanceId,State.Name,PublicIpAddress]' `
  --output table

# 4. Check target health
aws elbv2 describe-target-health `
  --target-group-arn $(aws elbv2 describe-target-groups --names ollama-tg --query 'TargetGroups[0].TargetGroupArn' --output text)

# 5. Wait for targets to become healthy (10-15 minutes total)
```

### Timeline
- **0-5 minutes**: Instances launch
- **5-15 minutes**: Ollama downloads model
- **15-25 minutes**: Instances become healthy and accessible

### Check Status

```powershell
# Quick status check
aws autoscaling describe-auto-scaling-groups `
  --auto-scaling-group-names ollama-asg `
  --query 'AutoScalingGroups[0].[DesiredCapacity,Instances[*].[InstanceId,HealthStatus]]'
```

### Your URLs (After Instances Are Healthy)

```
Open-WebUI: http://ollama-alb-2041931387.us-east-1.elb.amazonaws.com:8080
Ollama API: http://ollama-alb-2041931387.us-east-1.elb.amazonaws.com:11434
```

---

## Common Issues

### 1. Instances Not Launching

**Check:**
```powershell
aws autoscaling describe-scaling-activities `
  --auto-scaling-group-name ollama-asg `
  --max-records 5
```

**Possible causes:**
- EC2 instance limits reached
- Subnet has no available IPs
- Launch template issues

### 2. Instances Unhealthy

**Check instance logs:**
```powershell
# Get instance ID
$INSTANCE_ID = $(aws ec2 describe-instances `
  --filters "Name=tag:Name,Values=ollama-asg-instance" "Name=instance-state-name,Values=running" `
  --query 'Reservations[0].Instances[0].InstanceId' `
  --output text)

# Get console output
aws ec2 get-console-output --instance-id $INSTANCE_ID
```

### 3. Security Group Issues

**Verify security groups allow traffic:**
```powershell
# Check ALB security group
aws ec2 describe-security-groups --group-ids sg-06117938649ef2b1a

# Check app security group  
aws ec2 describe-security-groups --group-ids sg-000481d5454c9f6e5
```

### 4. Cost Concerns

If you want to stop paying for idle resources:

```powershell
# Scale down to 0 (stops all instances)
aws autoscaling set-desired-capacity `
  --auto-scaling-group-name ollama-asg `
  --desired-capacity 0 `
  --no-honor-cooldown

# Or destroy everything
cd infrastructure
terraform destroy
```

---

## Quick Fix Script

Save this as `fix-asg.ps1`:

```powershell
#!/usr/bin/env pwsh
Write-Host "🔧 Fixing Ollama ASG..." -ForegroundColor Cyan

# Scale up
Write-Host "📈 Scaling up to 2 instances..."
aws autoscaling set-desired-capacity --auto-scaling-group-name ollama-asg --desired-capacity 2

Write-Host "⏳ Waiting 30 seconds..."
Start-Sleep -Seconds 30

# Check status
Write-Host "📊 Current status:"
aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names ollama-asg --query 'AutoScalingGroups[0].[DesiredCapacity,Instances[*].[InstanceId,LifecycleState]]'

Write-Host ""
Write-Host "✅ Instances are launching!" -ForegroundColor Green
Write-Host "⏰ Wait 15-25 minutes for full initialization" -ForegroundColor Yellow
Write-Host ""
Write-Host "🌐 Your URLs (will be accessible once healthy):" -ForegroundColor Cyan
Write-Host "   Open-WebUI: http://ollama-alb-2041931387.us-east-1.elb.amazonaws.com:8080"
Write-Host "   Ollama API: http://ollama-alb-2041931387.us-east-1.elb.amazonaws.com:11434"
```

Run it:
```powershell
.\fix-asg.ps1
```

---

## Prevention

To prevent ASG from scaling to 0, update `infrastructure/asg.tf`:

```hcl
resource "aws_autoscaling_group" "app" {
  # ...
  min_size         = 2  # Ensures at least 2 instances always
  max_size         = 10
  desired_capacity = 2
  # ...
}
```

Then apply:
```powershell
cd infrastructure
terraform apply
```
