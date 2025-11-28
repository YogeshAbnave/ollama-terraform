# 🚀 EC2 Auto-Deploy - Ready to Deploy!

## ✅ Configuration Complete

Your EC2 auto-deployment is now fully configured and ready to use!

### What's Been Configured:

1. **✅ Terraform Configuration**
   - Variables defined for git repository, branch, and model
   - User-data template configured to clone and execute deployment script
   - All outputs configured (WebUI URL, SSH commands, status checks)

2. **✅ Git Repository**
   - Repository URL: `https://github.com/YogeshAbnave/ollama-terraform.git`
   - Branch: `main`
   - Deployment script: `ec2-deploy-ollama.sh` ✓

3. **✅ Deployment Script**
   - Idempotent installation (can run multiple times safely)
   - Automatic retry logic for git clone (3 attempts)
   - Comprehensive logging to `/var/log/user-data.log`
   - Status file creation at `/home/ubuntu/deployment-status.txt`

4. **✅ AI Model Configuration**
   - Default model: deepseek-r1:8b (option 1)
   - Can be changed in `terraform.tfvars`

---

## 🎯 Deploy Now

### Option 1: Quick Deploy (Recommended)

```powershell
# Verify everything is ready
.\verify-config.ps1

# Push your code to GitHub
git add .
git commit -m "Ready for EC2 auto-deploy"
git push origin main

# Deploy!
.\deploy.ps1
```

### Option 2: Manual Deploy

```powershell
# Initialize Terraform
terraform init

# Preview changes
terraform plan

# Deploy infrastructure
terraform apply

# Get outputs
terraform output
```

---

## 📊 What Happens During Deployment

### Phase 1: Infrastructure Creation (2-3 minutes)
- ✓ VPC and subnet configuration
- ✓ Security group creation (allows all traffic for testing)
- ✓ EC2 instance launch (Ubuntu 22.04)
- ✓ Public IP assignment

### Phase 2: Automated Installation (5-8 minutes)
The EC2 instance automatically:
1. Waits for cloud-init to complete
2. Clones your GitHub repository
3. Makes `ec2-deploy-ollama.sh` executable
4. Runs the installation script
5. Installs Ollama (via snap)
6. Installs Docker (via snap)
7. Downloads AI model (deepseek-r1:8b, ~4.9GB)
8. Deploys Open-WebUI container
9. Creates status file and logs

### Phase 3: Ready to Use
- ✓ WebUI accessible at `http://<your-ip>:8080`
- ✓ First user to register becomes admin
- ✓ Ollama API running on port 11434
- ✓ All logs available via SSH

---

## 🔍 Monitoring Deployment

### Check Terraform Outputs

After `terraform apply` completes:

```powershell
terraform output
```

You'll see:
- `webui_url` - Direct link to Open-WebUI
- `ssh_command` - Command to SSH into instance
- `deployment_log_command` - View deployment logs
- `deployment_status_command` - Check deployment status

### SSH into Instance

```bash
ssh -i ollama-key.pem ubuntu@<your-ip>
```

### View Real-Time Logs

```bash
# Watch deployment progress
sudo tail -f /var/log/user-data.log

# Check deployment status
cat /home/ubuntu/deployment-status.txt

# Verify services
sudo ss -tnlp | grep ollama
sudo docker ps | grep open-webui
```

---

## 🎨 Deployment Status File

The system creates a JSON status file at `/home/ubuntu/deployment-status.txt`:

```json
{
  "status": "success",
  "timestamp": "2025-11-29T10:20:45Z",
  "components": {
    "git_clone": "success",
    "ollama_install": "success",
    "docker_install": "success",
    "model_download": "success",
    "webui_deploy": "success"
  },
  "webui_url": "http://1.2.3.4:8080",
  "log_file": "/var/log/user-data.log"
}
```

---

## 🛠️ Customization Options

### Change AI Model

Edit `terraform.tfvars`:

```hcl
default_model = "2"  # Change to different model
```

Available models:
- `1` = deepseek-r1:8b (~4.9GB) - **Recommended**
- `2` = deepseek-r1:14b (~8.9GB)
- `3` = deepseek-r1:32b (~20GB)
- `4` = llama3.2:3b (~2GB) - Lightweight
- `5` = llama3.2:8b (~4.7GB)
- `6` = qwen2.5:7b (~4.7GB)

### Change Instance Type

Edit `terraform.tfvars`:

```hcl
instance_type = "t3.2xlarge"  # More powerful
storage_size  = 100           # More storage
```

### Use Different Branch

Edit `terraform.tfvars`:

```hcl
git_branch = "develop"  # Or any branch name
```

---

## 🚨 Troubleshooting

### Deployment Takes Too Long

**Normal**: 5-10 minutes total
**If longer**: SSH in and check logs

```bash
ssh -i ollama-key.pem ubuntu@<your-ip>
sudo tail -f /var/log/user-data.log
```

### Git Clone Fails

**Check**:
1. Repository is public and accessible
2. `ec2-deploy-ollama.sh` exists in repo root
3. Branch name is correct

**Fix**: The script retries 3 times automatically

### WebUI Not Accessible

**Wait**: Give it 10 minutes for model download
**Check**:
```bash
sudo docker ps | grep open-webui
curl http://localhost:11434/api/tags
```

### Installation Fails

**SSH in and manually run**:
```bash
cd /home/ubuntu/deployment
./ec2-deploy-ollama.sh install
```

---

## 📚 Documentation Files

- `SETUP-INSTRUCTIONS.md` - Detailed setup guide
- `DEPLOYMENT-READY.md` - This file (quick reference)
- `COMPLETE-GUIDE.md` - Comprehensive documentation
- `verify-config.ps1` - Configuration verification script

---

## 🎉 Success Checklist

After deployment completes:

- [ ] Terraform apply succeeded
- [ ] WebUI URL displayed in outputs
- [ ] Can access `http://<your-ip>:8080`
- [ ] Can register first user (becomes admin)
- [ ] Can select AI model in WebUI
- [ ] Can send messages and get responses

---

## 💡 Tips

1. **First deployment**: Takes longer due to model download
2. **Subsequent deployments**: Faster if model is cached
3. **Cost optimization**: Stop instance when not in use
4. **Security**: Update `allowed_ssh_cidr` to your IP only
5. **Backup**: Export conversations before destroying infrastructure

---

## 🔗 Quick Links

- **Repository**: https://github.com/YogeshAbnave/ollama-terraform
- **Ollama Models**: https://ollama.ai/library
- **Open-WebUI Docs**: https://docs.openwebui.com/

---

## 🚀 Ready to Deploy?

```powershell
.\verify-config.ps1  # Verify configuration
git push origin main  # Push your code
.\deploy.ps1          # Deploy!
```

**Estimated time**: 10 minutes from start to finish

**Result**: Fully functional AI assistant with web interface! 🎉
