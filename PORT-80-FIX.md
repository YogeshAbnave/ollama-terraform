# Port 80 Fix - Production-Ready UI Access

## Problem
Open-WebUI was only accessible on port 8080, requiring users to specify the port in the URL:
```
http://ollama-alb-2041931387.us-east-1.elb.amazonaws.com:8080  ❌
```

This is not production-ready. Users expect standard HTTP on port 80.

## Solution
Updated the infrastructure to make Open-WebUI accessible on standard port 80:
```
http://ollama-alb-2041931387.us-east-1.elb.amazonaws.com  ✅
```

## Changes Made

### 1. Docker Port Mapping (`infrastructure/scripts/user_data.sh`)
**Before:**
```bash
docker run -d \
  --name open-webui \
  -p 8080:8080 \
  ...
```

**After:**
```bash
docker run -d \
  --name open-webui \
  -p 80:8080 \
  ...
```

This maps the host's port 80 to the container's internal port 8080.

### 2. ALB Target Group (`infrastructure/alb.tf`)
**Before:**
```hcl
resource "aws_lb_target_group" "app" {
  name     = "ollama-tg"
  port     = var.open_webui_port  # 8080
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
```

**After:**
```hcl
resource "aws_lb_target_group" "app" {
  name     = "ollama-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
```

### 3. Security Group (`infrastructure/security-groups.tf`)
**Before:**
```hcl
ingress {
  description     = "Open-WebUI from ALB"
  from_port       = var.open_webui_port  # 8080
  to_port         = var.open_webui_port
  protocol        = "tcp"
  security_groups = [aws_security_group.alb.id]
}
```

**After:**
```hcl
ingress {
  description     = "Open-WebUI from ALB"
  from_port       = 80
  to_port         = 80
  protocol        = "tcp"
  security_groups = [aws_security_group.alb.id]
}
```

## Traffic Flow (After Fix)

```
User Browser
    ↓
    | HTTP Port 80
    ↓
Application Load Balancer (Port 80)
    ↓
    | Forward to Target Group (Port 80)
    ↓
EC2 Instance (Port 80)
    ↓
    | Docker port mapping 80:8080
    ↓
Open-WebUI Container (Internal Port 8080)
```

## How to Apply

Run the fix script:
```powershell
.\fix-port-80.ps1
```

This will:
1. Apply Terraform changes
2. Terminate old instances
3. Launch new instances with updated configuration
4. Wait for instances to become healthy

## Timeline

- **0-5 min**: Instances launching
- **5-15 min**: Docker containers starting, Ollama downloading model
- **15-25 min**: ✅ **Ready on port 80!**

## Verification

Check target health:
```powershell
aws elbv2 describe-target-health `
  --target-group-arn $(aws elbv2 describe-target-groups --names ollama-tg --query 'TargetGroups[0].TargetGroupArn' --output text)
```

Test the URL:
```powershell
curl http://ollama-alb-2041931387.us-east-1.elb.amazonaws.com
```

## Production Benefits

✅ **Standard HTTP port** - No port number needed in URL
✅ **Professional appearance** - Clean URLs for users
✅ **Firewall friendly** - Port 80 is rarely blocked
✅ **SSL ready** - Easy to add HTTPS on port 443 later
✅ **Production best practice** - Follows industry standards

## Next Steps (Optional)

For even better production setup, consider:
1. Add HTTPS support with ACM certificate
2. Redirect HTTP to HTTPS
3. Add custom domain name
4. Enable WAF for security

