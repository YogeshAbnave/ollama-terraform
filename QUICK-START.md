# 🚀 Quick Start - Deploy Ollama to AWS

## Prerequisites Check

```powershell
aws --version        # AWS CLI v2.x
terraform version    # Terraform v1.5+
pwsh --version      # PowerShell 7.x
```

## Step 1: Configure AWS

```bash
aws configure
# Enter AWS Access Key ID
# Enter AWS Secret Access Key
# Enter region: us-east-1
# Enter output format: json

# Verify
aws sts get-caller-identity
```

## Step 2: Deploy

```powershell
.\scripts\deploy.ps1
```

That's it! The script will:
1. ✅ Validate prerequisites
2. ✅ Initialize Terraform
3. ✅ Deploy infrastructure
4. ✅ Show access URLs

## Step 3: Wait

- **10-25 minutes** for full initialization
- Ollama downloads the model automatically

## Step 4: Access

```
🌐 Open-WebUI: http://your-alb-dns:8080
🤖 Ollama API: http://your-alb-dns:11434
```

Open the URL, create an account, start chatting!

---

## What You Just Deployed

- 2-10 EC2 instances (auto-scales)
- Load Balancer
- DynamoDB database
- S3 + CloudFront storage
- CloudWatch monitoring
- Multi-AZ high availability

**Cost**: ~$330-$1,290/month (scales with load)

---

## Quick Commands

```bash
# Check status
aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names ollama-asg

# View logs
aws logs tail /aws/ec2/ollama-app --follow

# Test API
curl http://your-alb-dns:11434/api/tags

# Destroy
.\scripts\destroy.ps1
```

---

## Customize

Edit `infrastructure/terraform.tfvars`:

```hcl
instance_type = "t3.2xlarge"     # Bigger instances
ollama_model  = "llama3.2:8b"    # Different model
```

Then redeploy: `.\scripts\deploy.ps1`

---

**That's it! You're running Ollama on AWS!** 🎉
