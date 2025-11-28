# 🚀 Ollama + Open-WebUI EC2 Deployment - Complete Guide

Complete guide for deploying Ollama with Open-WebUI on AWS EC2.

---

## 📋 Table of Contents

1. [Quick Start](#quick-start)
2. [What This Does](#what-this-does)
3. [EC2 Configuration](#ec2-configuration)
4. [Deployment Methods](#deployment-methods)
5. [Windows Users](#windows-users)
6. [Management](#management)
7. [Troubleshooting](#troubleshooting)
8. [Cost Information](#cost-information)

---

## 🎯 Quick Start

### Already Deployed? Access Now!

**Your Instance:**
- Public IP: Check with `terraform output`
- WebUI: `http://<YOUR-IP>:8080`
- SSH: `ssh -i ollama-key.pem ubuntu@<YOUR-IP>`

### New Deployment - 3 Steps:

**1. Install Prerequisites**
```powershell
# Windows
choco install terraform awscli

# Configure AWS
aws configure
```

**2. Deploy with Terraform**
```powershell
# Copy configuration
Copy-Item terraform.tfvars.example terraform.tfvars
notepad terraform.tfvars  # Edit with your values

# Deploy
terraform init
terraform apply
```

**3. Access**
```powershell
# Get URL
terraform output webui_url

# Open in browser (wait 5-10 minutes for installation)
```

---

## 🎯 What This Does

This project deploys:
- ✅ **Ollama** - LLM runtime for running AI models
- ✅ **Open-WebUI** - ChatGPT-like web interface
- ✅ **AI Model** - deepseek-r1:8b (or your choice)
- ✅ **Complete Infrastructure** - VPC, security groups, monitoring

**Result:** Your own private AI assistant running on AWS!

---

## 💻 EC2Configuration

### Recommended Configurations

| Use Case | Instance | RAM | Storage | Cost/Month |
|----------|----------|-----|---------|------------|
| **Testing** | t3.large | 8 GB | 30 GB | $60 |
| **Production** ⭐ | t3.xlarge | 16 GB | 50 GB | $120 |
| **High Performance** | c5.2xlarge | 32 GB | 100 GB | $250 |
| **GPU** | g4dn.xlarge | 16 GB | 100 GB | $380 |

**Recommendation:** t3.xlarge with deepseek-r1:8b

### Available Models

| Model | Size | RAM Required | Best For |
|-------|------|--------------|----------|
| llama3.2:3b | 2 GB | 4 GB | Testing |
| **deepseek-r1:8b** ⭐ | 4.9 GB | 8 GB | **Recommended** |
| deepseek-r1:14b | 8.9 GB | 16 GB | Better quality |
| deepseek-r1:32b | 20 GB | 32 GB | Best quality |

---

## 🚀 Deployment Methods

### Method 1: Terraform (Recommended)

**Best for:** Everyone, especially Windows users

```powershell
# 1. Configure
Copy-Item terraform.tfvars.example terraform.tfvars
notepad terraform.tfvars

# Edit these values:
# aws_region = "us-east-1"
# instance_type = "t3.xlarge"
# storage_size = 50
# key_name = "your-key-name"
# allowed_ssh_cidr = "YOUR.IP/32"

# 2. Deploy
terraform init
terraform plan
terraform apply

# 3. Get outputs
terraform output
```

**Time:** 10 minutes

---

### Method 2: Manual Deployment

**Best for:** Learning, more control

**Step 1: Launch EC2**
1. Go to AWS Console → EC2 → Launch Instance
2. Choose Ubuntu 22.04 LTS
3. Select t3.xlarge
4. Configure security group (ports 22, 8080)
5. Launch

**Step 2: Connect**
```powershell
ssh -i your-key.pem ubuntu@<EC2-IP>
```

**Step 3: Deploy**
```bash
# On EC2 instance
curl -fsSL https://raw.githubusercontent.com/your-repo/main/ec2-deploy-ollama.sh -o deploy.sh
chmod +x deploy.sh
./deploy.sh install
```

**Time:** 15 minutes

---

### Method 3: GitHub Actions

**Best for:** Teams, automation

1. Push code to GitHub
2. Configure secrets in repo settings
3. Trigger workflow
4. Access application

**Time:** 15 minutes (automated)

---

## 🪟 Windows Users

### Important: Where to Run What

**On Windows (PowerShell):**
- ✅ `terraform` commands
- ✅ `aws` commands
- ✅ `ssh` to connect
- ❌ Cannot run `.sh` scripts

**On EC2 (after SSH):**
- ✅ `./deploy.sh` commands
- ✅ `ollama` commands
- ✅ `docker` commands

### Quick Windows Setup

```powershell
# Install tools
choco install terraform awscli

# Configure AWS
aws configure

# Get your IP
Invoke-RestMethod -Uri 'https://api.ipify.org?format=text'

# Deploy
terraform init
terraform apply

# Access
terraform output webui_url
```

---

## 🛠️ Management

### Check Status

```powershell
# Get all outputs
terraform output

# Check specific values
terraform output webui_url
terraform output ssh_command
```

### SSH into Instance

```powershell
# Connect
ssh -i ollama-key.pem ubuntu@<PUBLIC-IP>

# Check installation log
sudo tail -f /var/log/user-data.log

# Check services
sudo docker ps
ollama list
```

### Manage Services

```bash
# On EC2 instance

# Restart Ollama
sudo snap restart ollama

# Restart Open-WebUI
sudo docker restart open-webui

# Check logs
sudo docker logs open-webui
sudo snap logs ollama

# List models
ollama list

# Remove model
ollama rm model-name

# Add model
ollama run llama3.2:3b
```

### Stop/Start Instance

```powershell
# Stop (saves money)
aws ec2 stop-instances --instance-ids <INSTANCE-ID>

# Start
aws ec2 start-instances --instance-ids <INSTANCE-ID>

# Get new IP after start
terraform refresh
terraform output
```

### Destroy Everything

```powershell
# Remove all resources
terraform destroy

# Confirm with 'yes'
```

---

## 🐛 Troubleshooting

### Can't Access WebUI

**Check 1: Wait**
- Installation takes 5-10 minutes
- Check: `sudo tail -f /var/log/user-data.log`

**Check 2: Security Group**
```powershell
# Verify port 8080 is open
aws ec2 describe-security-groups --group-ids <SG-ID>
```

**Check 3: Services Running**
```bash
# On EC2
sudo docker ps
sudo ss -tnlp | grep 8080
```

**Fix:**
```bash
sudo docker restart open-webui
```

---

### Can't SSH

**Issue: Permission denied**
```powershell
# Fix key permissions (Windows)
icacls ollama-key.pem /inheritance:r
icacls ollama-key.pem /grant:r "$($env:USERNAME):(R)"
```

**Issue: Connection refused**
- Check security group allows SSH from your IP
- Verify your IP hasn't changed
- Check instance is running

---

### Out of Storage

```bash
# Check usage
df -h

# Remove unused models
ollama list
ollama rm model-name

# Clean Docker
sudo docker system prune -a
```

---

### Out of Memory

```bash
# Check usage
free -h

# Use smaller model
ollama rm deepseek-r1:14b
ollama run llama3.2:3b

# Or upgrade instance type
```

---

### Ollama Not Responding

```bash
# Check if running
sudo ss -tnlp | grep ollama

# Restart
sudo snap restart ollama

# Test API
curl http://localhost:11434/api/tags

# Check logs
sudo snap logs ollama
```

---

## 💰 Cost Information

### Monthly Costs (On-Demand)

| Instance | Cost/Month | Use Case |
|----------|------------|----------|
| t3.large | $60 | Testing |
| t3.xlarge | $120 | Production |
| c5.2xlarge | $250 | High performance |
| g4dn.xlarge | $380 | GPU acceleration |

### Cost Optimization

**1. Use Spot Instances (Save 70-90%)**
```hcl
# In terraform-ec2.tf, use spot instances
# t3.xlarge: $120/mo → $36/mo
```

**2. Stop When Not in Use**
```powershell
# Stop instance
aws ec2 stop-instances --instance-ids <ID>

# Start when needed
aws ec2 start-instances --instance-ids <ID>
```

**3. Reserved Instances (Save 40-72%)**
- 1-year commitment
- t3.xlarge: $120/mo → $72/mo

**4. Right-Size**
- Start with t3.large ($60/mo)
- Upgrade if needed

**5. Set Budget Alerts**
```powershell
# AWS Console → Billing → Budgets
# Set alert at $100/month
```

---

## 🔒 Security

### Security Group Rules

| Type | Port | Source | Purpose |
|------|------|--------|---------|
| SSH | 22 | Your IP | Remote access |
| HTTP | 8080 | 0.0.0.0/0 | WebUI |
| Custom | 11434 | 127.0.0.1/32 | Ollama API |

### Best Practices

1. **Restrict SSH** - Only allow your IP
2. **Use IAM Roles** - No hardcoded credentials
3. **Enable Monitoring** - CloudWatch alarms
4. **Regular Updates** - Keep OS patched
5. **Backup Data** - Regular snapshots
6. **Use HTTPS** - Add SSL/TLS for production

---

## 📊 Monitoring

### CloudWatch Metrics

Automatically created:
- CPU utilization alarm (>80%)
- View in AWS Console → CloudWatch

### Check Resources

```bash
# On EC2
htop              # CPU/Memory
df -h             # Disk
sudo docker stats # Container stats
```

---

## 🔄 Backup & Recovery

### Create Backup

```powershell
# Create AMI snapshot
aws ec2 create-image \
  --instance-id <INSTANCE-ID> \
  --name "ollama-backup-$(Get-Date -Format 'yyyyMMdd')"
```

### Backup Data

```bash
# On EC2 - backup Open-WebUI data
sudo docker run --rm \
  -v open-webui:/data \
  -v $(pwd):/backup \
  ubuntu tar czf /backup/webui-backup.tar.gz /data
```

---

## 📚 File Structure

```
.
├── ec2-deploy-ollama.sh          # Main deployment script
├── terraform-ec2.tf              # Infrastructure config
├── terraform.tfvars              # Your configuration
├── terraform.tfvars.example      # Config template
├── .github/workflows/deploy.yml  # CI/CD automation
├── COMPLETE-GUIDE.md             # This file
└── README.md                     # Quick overview
```

---

## 🎓 Common Tasks

### Change Model

```bash
# SSH into instance
ssh -i ollama-key.pem ubuntu@<IP>

# Remove current model
ollama rm deepseek-r1:8b

# Install new model
ollama run llama3.2:3b
```

### Upgrade Instance

```powershell
# 1. Stop instance
aws ec2 stop-instances --instance-ids <ID>

# 2. Change instance type
aws ec2 modify-instance-attribute \
  --instance-id <ID> \
  --instance-type t3.2xlarge

# 3. Start instance
aws ec2 start-instances --instance-ids <ID>
```

### Add Storage

```powershell
# 1. Create snapshot
aws ec2 create-snapshot --volume-id <VOL-ID>

# 2. Modify volume
aws ec2 modify-volume --volume-id <VOL-ID> --size 100

# 3. Extend filesystem (on EC2)
sudo growpart /dev/nvme0n1 1
sudo resize2fs /dev/nvme0n1p1
```

---

## ✅ Quick Reference

### Essential Commands

```powershell
# Windows
terraform output              # Get all info
terraform output webui_url    # Get URL
terraform destroy             # Remove everything
ssh -i ollama-key.pem ubuntu@<IP>  # Connect

# On EC2
./deploy.sh status            # Check status
./deploy.sh cleanup           # Management menu
ollama list                   # List models
sudo docker ps                # List containers
sudo docker logs open-webui   # View logs
```

### Important URLs

- **WebUI:** http://<YOUR-IP>:8080
- **AWS Console:** https://console.aws.amazon.com/ec2/
- **Ollama Docs:** https://github.com/ollama/ollama
- **Open-WebUI Docs:** https://github.com/open-webui/open-webui

---

## 🆘 Getting Help

### Check Logs

```bash
# Installation log
sudo tail -f /var/log/user-data.log

# Docker logs
sudo docker logs open-webui

# Ollama logs
sudo snap logs ollama

# System logs
sudo journalctl -xe
```

### Common Issues

1. **WebUI not loading** → Wait 10 minutes, check logs
2. **Can't SSH** → Check security group, key permissions
3. **Out of storage** → Remove unused models
4. **Slow responses** → Upgrade instance or use smaller model
5. **High costs** → Stop instance when not in use

---

## 🎉 Success Checklist

- [ ] EC2 instance running
- [ ] Can access WebUI at http://<IP>:8080
- [ ] Created admin account
- [ ] Model responding to queries
- [ ] SSH access working
- [ ] Monitoring configured
- [ ] Budget alerts set
- [ ] Backup created

---

## 📞 Support

- **Documentation:** This file
- **AWS Support:** https://console.aws.amazon.com/support/
- **Ollama:** https://github.com/ollama/ollama
- **Open-WebUI:** https://github.com/open-webui/open-webui

---

**Deployment Time:** 10-15 minutes  
**Difficulty:** Easy  
**Cost:** Starting at $60/month  

**Your AI assistant is ready! 🚀**
