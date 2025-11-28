# 🚀 Quick Deploy Guide - Push and Go!

## One-Time Setup (Do This Once)

### 1. Configure Your Repository

```powershell
# Set your git repository URL (already done!)
# terraform.tfvars already has:
# git_repo_url = "https://github.com/YogeshAbnave/ollama-terraform.git"
```

### 2. Verify Everything is Ready

```powershell
.\verify-config.ps1
```

---

## Every Time You Want to Deploy

### Simple 3-Step Process:

```powershell
# Step 1: Push your code to GitHub
git add .
git commit -m "Update deployment"
git push origin main

# Step 2: Deploy infrastructure
.\deploy.ps1

# Step 3: Wait 10 minutes and access your WebUI!
```

That's it! ✨

---

## What Happens Automatically

### When You Run `.\deploy.ps1`:

1. ✅ **Checks prerequisites** (Terraform, AWS CLI)
2. ✅ **Gets your public IP** for SSH access
3. ✅ **Creates/reuses SSH key** (ollama-key.pem)
4. ✅ **Generates terraform.tfvars** with your settings
5. ✅ **Runs terraform apply** to create infrastructure
6. ✅ **Displays WebUI URL** when complete

### On the EC2 Instance (Automatic):

1. ✅ **Instance boots** with Ubuntu 22.04
2. ✅ **Cloud-init completes** system initialization
3. ✅ **Updates packages** (`apt-get update`)
4. ✅ **Installs git** (`apt-get install git`)
5. ✅ **Clones your repo** from GitHub (3 retry attempts)
6. ✅ **Makes script executable** (`chmod +x ec2-deploy-ollama.sh`)
7. ✅ **Runs installation** (`./ec2-deploy-ollama.sh install`)
8. ✅ **Installs Ollama** via snap
9. ✅ **Installs Docker** via snap
10. ✅ **Downloads AI model** (deepseek-r1:8b, ~4.9GB)
11. ✅ **Starts Open-WebUI** container
12. ✅ **Creates status file** at `/home/ubuntu/deployment-status.txt`
13. ✅ **Logs everything** to `/var/log/user-data.log`

**Total Time: ~10 minutes** ⏱️

---

## Workflow Examples

### Scenario 1: First Time Deployment

```powershell
# Make sure code is on GitHub
git add .
git commit -m "Initial deployment setup"
git push origin main

# Deploy
.\deploy.ps1

# Wait for completion message, then:
# Open the WebUI URL shown in the output
```

### Scenario 2: Update Deployment Script

```powershell
# Edit ec2-deploy-ollama.sh
# ... make your changes ...

# Push to GitHub
git add ec2-deploy-ollama.sh
git commit -m "Update deployment script"
git push origin main

# Destroy old infrastructure
terraform destroy -auto-approve

# Deploy fresh (will pull latest code)
.\deploy.ps1
```

### Scenario 3: Change AI Model

```powershell
# Edit terraform.tfvars
# Change: default_model = "2"  # For deepseek-r1:14b

# No need to push (this is local config)

# Destroy and redeploy
terraform destroy -auto-approve
.\deploy.ps1
```

### Scenario 4: Update Configuration

```powershell
# Edit any configuration files
# ... make changes ...

# Push to GitHub
git add .
git commit -m "Update configuration"
git push origin main

# Redeploy
terraform destroy -auto-approve
.\deploy.ps1
```

---

## Monitoring Your Deployment

### Check Status Anytime

```powershell
# Quick status check
.\check-user-data.ps1

# Or manually
$IP = terraform output -raw instance_public_ip
ssh -i ollama-key.pem ubuntu@$IP 'cat /home/ubuntu/deployment-status.txt'
```

### Watch Live Logs

```powershell
# Watch deployment progress in real-time
$IP = terraform output -raw instance_public_ip
ssh -i ollama-key.pem ubuntu@$IP 'sudo tail -f /var/log/user-data.log'
```

### Get WebUI URL

```powershell
# Display the URL
terraform output webui_url

# Open in browser automatically
Start-Process $(terraform output -raw webui_url)
```

---

## Troubleshooting

### If Deployment Fails

```powershell
# Check what went wrong
.\check-user-data.ps1

# View detailed troubleshooting
# See TROUBLESHOOTING.md
```

### If You Need to Start Over

```powershell
# Complete cleanup and fresh start
terraform destroy -auto-approve
Start-Sleep -Seconds 120  # Wait 2 minutes
.\deploy.ps1
```

### If Repository Not Cloning

```powershell
# Verify repository is accessible
git ls-remote https://github.com/YogeshAbnave/ollama-terraform.git

# If this fails, make sure:
# 1. Repository is public
# 2. Repository URL is correct
# 3. You have internet connectivity
```

---

## Customization

### Change AI Model

Edit `terraform.tfvars`:
```hcl
default_model = "1"  # Options: 1-6
```

Models:
- `1` = deepseek-r1:8b (~4.9GB) ⭐ Recommended
- `2` = deepseek-r1:14b (~8.9GB)
- `3` = deepseek-r1:32b (~20GB)
- `4` = llama3.2:3b (~2GB)
- `5` = llama3.2:8b (~4.7GB)
- `6` = qwen2.5:7b (~4.7GB)

### Change Instance Size

Edit `terraform.tfvars`:
```hcl
instance_type = "t3.2xlarge"  # More powerful
storage_size  = 100           # More storage
```

### Change Region

Edit `terraform.tfvars`:
```hcl
aws_region = "us-west-2"  # Different region
```

---

## Cost Management

### Stop Instance When Not Using

```powershell
# Stop instance (keeps data, stops charges)
aws ec2 stop-instances --instance-ids $(terraform output -raw instance_id)

# Start instance when needed
aws ec2 start-instances --instance-ids $(terraform output -raw instance_id)

# Get new IP after starting
terraform refresh
terraform output webui_url
```

### Destroy Everything

```powershell
# Complete cleanup (deletes everything)
terraform destroy -auto-approve
```

---

## Success Checklist

After running `.\deploy.ps1`, you should see:

- ✅ Terraform apply completed successfully
- ✅ WebUI URL displayed in output
- ✅ Can SSH into instance
- ✅ After 10 minutes, can access WebUI
- ✅ Can register first user (becomes admin)
- ✅ Can chat with AI model

---

## Quick Reference Commands

```powershell
# Deploy
git push origin main && .\deploy.ps1

# Check status
.\check-user-data.ps1

# Get URL
terraform output webui_url

# Watch logs
ssh -i ollama-key.pem ubuntu@$(terraform output -raw instance_public_ip) 'sudo tail -f /var/log/user-data.log'

# Redeploy
terraform destroy -auto-approve && .\deploy.ps1

# Verify config
.\verify-config.ps1
```

---

## The Complete Workflow

```powershell
# 1. Make changes to your code
code ec2-deploy-ollama.sh

# 2. Test locally if needed
# ... test your changes ...

# 3. Commit and push
git add .
git commit -m "Improve deployment"
git push origin main

# 4. Deploy to AWS
.\deploy.ps1

# 5. Monitor deployment
.\check-user-data.ps1

# 6. Access WebUI (after ~10 minutes)
Start-Process $(terraform output -raw webui_url)

# 7. Use your AI assistant!
# First user to register becomes admin
```

---

## Tips for Smooth Deployments

1. **Always push before deploying**
   ```powershell
   git push origin main  # Ensure latest code is on GitHub
   .\deploy.ps1          # Then deploy
   ```

2. **Wait for completion**
   - Infrastructure: 2-3 minutes
   - Installation: 5-8 minutes
   - Total: ~10 minutes

3. **Check logs if issues**
   ```powershell
   .\check-user-data.ps1  # Quick diagnostic
   ```

4. **Destroy old before new**
   ```powershell
   terraform destroy -auto-approve  # Clean up old
   .\deploy.ps1                     # Deploy fresh
   ```

5. **Keep terraform.tfvars updated**
   - Don't commit this file (has your IP)
   - Update `allowed_ssh_cidr` if your IP changes

---

## What Gets Deployed

### Infrastructure (via Terraform):
- VPC and subnet (reuses existing)
- Security group (SSH, HTTP, Ollama API)
- EC2 instance (Ubuntu 22.04)
- Public IP address
- CloudWatch monitoring

### Software (via user-data script):
- Git
- Ollama (AI model runtime)
- Docker (container runtime)
- AI Model (deepseek-r1:8b by default)
- Open-WebUI (web interface)

### Configuration:
- All logs → `/var/log/user-data.log`
- Status file → `/home/ubuntu/deployment-status.txt`
- Repository → `/home/ubuntu/deployment/`
- WebUI → `http://<ip>:8080`

---

## Ready to Deploy?

```powershell
# Verify everything is ready
.\verify-config.ps1

# Push your code
git add .
git commit -m "Ready to deploy"
git push origin main

# Deploy!
.\deploy.ps1

# ✨ Magic happens! ✨
# Wait 10 minutes, then access your AI assistant!
```

**That's it! Your deployment is now fully automated!** 🎉
