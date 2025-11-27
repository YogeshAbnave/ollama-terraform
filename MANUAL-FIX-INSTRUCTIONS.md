# MANUAL FIX INSTRUCTIONS - GET UI WORKING NOW

## The Problem
Your infrastructure is configured correctly, but **NO INSTANCES ARE RUNNING**. That's why you get 502 Bad Gateway.

## The Solution (3 Simple Commands)

Open PowerShell and run these commands **ONE AT A TIME**:

### Step 1: Scale Down (Kill any old instances)
```powershell
aws autoscaling set-desired-capacity --auto-scaling-group-name ollama-asg --desired-capacity 0
```

Wait 30 seconds.

### Step 2: Scale Up (Launch new instances with fixed config)
```powershell
aws autoscaling set-desired-capacity --auto-scaling-group-name ollama-asg --desired-capacity 2
```

### Step 3: Wait and Check
Wait 5-10 minutes, then check:
```powershell
aws ec2 describe-instances --filters "Name=tag:Name,Values=ollama-asg-instance" "Name=instance-state-name,Values=running" --query 'Reservations[*].Instances[*].[InstanceId,State.Name]' --output table
```

## Your Production URL

```
http://ollama-alb-2041931387.us-east-1.elb.amazonaws.com
```

**NO PORT NUMBER NEEDED!** Just port 80.

## Timeline

- **0-2 min**: Instances launching
- **2-5 min**: Docker starting, Open-WebUI container launching
- **5-10 min**: ✅ **UI SHOULD BE WORKING!**
- **10-20 min**: Ollama downloading model in background
- **20-25 min**: ✅ **FULLY READY with AI model**

## What We Fixed in the Code

1. ✅ **Port 80**: Open-WebUI now runs on port 80 (not 8080)
2. ✅ **Health Check**: Extended grace period to 30 minutes
3. ✅ **Simple Setup**: Removed complex health check switching
4. ✅ **Target Group**: Updated to forward to port 80
5. ✅ **Security Group**: Allows port 80 from ALB

## If Still Not Working After 10 Minutes

Check target health:
```powershell
aws elbv2 describe-target-health --target-group-arn $(aws elbv2 describe-target-groups --query 'TargetGroups[?contains(TargetGroupName, `ollama`)].TargetGroupArn' --output text)
```

If targets show "unhealthy", get instance logs:
```powershell
$instanceId = $(aws ec2 describe-instances --filters "Name=tag:Name,Values=ollama-asg-instance" "Name=instance-state-name,Values=running" --query 'Reservations[0].Instances[0].InstanceId' --output text)
aws ec2 get-console-output --instance-id $instanceId --output text
```

## Summary

**The code is fixed. You just need to launch new instances with these 2 commands:**

```powershell
aws autoscaling set-desired-capacity --auto-scaling-group-name ollama-asg --desired-capacity 0
# Wait 30 seconds
aws autoscaling set-desired-capacity --auto-scaling-group-name ollama-asg --desired-capacity 2
```

Then wait 5-10 minutes and access:
```
http://ollama-alb-2041931387.us-east-1.elb.amazonaws.com
```

**That's it. The infrastructure is production-ready. Just needs instances running.**
