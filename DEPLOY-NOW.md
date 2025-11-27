# 🎯 Deploy Ollama to AWS - Production Ready

## ✅ Status: READY TO DEPLOY

Your infrastructure is configured for production deployment.

---

## 🚀 Deploy Command

```powershell
.\scripts\deploy.ps1
```

**That's it!** The script handles everything.

---

## 📋 What Happens

1. **Validates** AWS CLI, Terraform, credentials
2. **Confirms** deployment (type "DEPLOY")
3. **Initializes** Terraform
4. **Creates** infrastructure plan
5. **Deploys** to AWS (5-10 minutes)
6. **Shows** access URLs

---

## ⏱️ Timeline

- **Deployment**: 5-10 minutes
- **Initialization**: 10-15 minutes
- **Total**: ~15-25 minutes

---

## 🌐 After Deployment

You'll get:

```
🌐 Open-WebUI URL:
   http://ollama-alb-xxxxx.us-east-1.elb.amazonaws.com:8080

🤖 Ollama API URL:
   http://ollama-alb-xxxxx.us-east-1.elb.amazonaws.com:11434

🔑 SSH Key:
   .ssh/ollama-key
```

---

## 📊 What's Deployed

- **2-10 EC2 instances** (t3.xlarge, auto-scales)
- **Load Balancer** (distributes traffic)
- **DynamoDB** (data storage with PITR)
- **S3 + CloudFront** (file storage + CDN)
- **CloudWatch** (monitoring + alarms)
- **Multi-AZ** (high availability)

---

## 💰 Cost

**~$330-$1,290/month** (scales with load)

Breakdown:
- EC2: $240-$1,200
- Load Balancer: $20
- Data Transfer: $50
- Storage: $20

---

## 🔧 Customize (Optional)

Edit `infrastructure/terraform.tfvars` before deploying:

```hcl
instance_type = "t3.2xlarge"     # Bigger instances
ollama_model  = "llama3.2:8b"    # Different model
aws_region    = "us-west-2"      # Different region
```

---

## ✅ Prerequisites

Ensure you have:

- [x] AWS CLI installed
- [x] Terraform installed
- [x] PowerShell 7+ installed
- [x] AWS credentials configured (`aws configure`)

---

## 🎯 Deploy Now

```powershell
# Navigate to project
cd /path/to/ollama-terraform

# Deploy
.\scripts\deploy.ps1

# Wait 15-25 minutes
# Access Open-WebUI at the URL shown
# Create account and start chatting!
```

---

## 🗑️ Destroy Later

```powershell
.\scripts\destroy.ps1
```

Requires typing "DESTROY" and "YES" to confirm.

---

## 📚 Documentation

- **Quick Start**: [QUICK-START.md](QUICK-START.md)
- **Full Guide**: [README.md](README.md)

---

## 🎉 Ready?

```powershell
.\scripts\deploy.ps1
```

**Deploy now and get Ollama running on AWS in 15 minutes!** 🚀🤖✨
