# EC2 Auto-Deploy Setup Instructions

## What Was Fixed

The infrastructure is now configured to automatically:
1. Clone your git repository when the EC2 instance boots
2. Execute the `ec2-deploy-ollama.sh` script from the cloned repository
3. Install Ollama, Docker, and Open-WebUI automatically

## Quick Start Guide

### 1. Verify Configuration (Recommended)

Run the verification script to ensure everything is configured correctly:

```powershell
.\verify-config.ps1
```

This will check:
- ✓ Terraform and AWS CLI are installed
- ✓ All required files exist
- ✓ Git repository URL is configured
- ✓ Terraform variables are set
- ✓ User-data template is correct

### 2. Push Your Code to GitHub

Make sure all your files are committed and pushed:

```bash
git add .
git commit -m "Configure EC2 auto-deploy"
git push origin main
```

### 3. Deploy Infrastructure

```powershell
.\deploy.ps1
```

Or manually:
```powershell
terraform init
terraform plan
terraform apply
```

### 4. Wait for Deployment

The deployment takes 5-10 minutes. You'll see the WebUI URL in the Terraform outputs.

### 5. Access Your WebUI

Open the URL shown in the outputs: `http://<your-ip>:8080`

---

## Detailed Configuration

### Step 1: Verify Your Git Repository URL ✅

Your `terraform.tfvars` is already configured with your repository:

```hcl
# Git Repository Configuration
git_repo_url  = "https://github.com/YogeshAbnave/ollama-terraform.git"
git_branch    = "main"
default_model = "1"  # 1=deepseek-r1:8b (recommended)
```

**✅ Configuration Complete!** 

**Important**: 
- Your repository is publicly accessible ✓
- The repository contains the `ec2-deploy-ollama.sh` file ✓

### Step 2: Commit Your Code to Git

Make sure your current code (including `ec2-deploy-ollama.sh`) is pushed to your git repository:

```bash
git add .
git commit -m "Add EC2 deployment automation"
git push origin main
```

### Step 3: Deploy with Terraform

Run your deployment:

```powershell
.\deploy.ps1
```

Or manually:

```powershell
terraform init
terraform plan
terraform apply
```

## How It Works

When the EC2 instance boots:

1. **Cloud-init waits** for the system to be ready
2. **Git clone** - The user-data script clones your repository to `/home/ubuntu/deployment/`
   - Retries up to 3 times if it fails
   - Sets proper file ownership (ubuntu:ubuntu)
3. **Execute script** - Runs `ec2-deploy-ollama.sh install` with the default model selection
4. **Install everything** - The script installs:
   - Ollama (via snap)
   - Docker (via snap)
   - AI model (deepseek-r1:8b by default)
   - Open-WebUI container
5. **Create status file** - Writes deployment status to `/home/ubuntu/deployment-status.txt`
6. **Log everything** - All output goes to `/var/log/user-data.log`

## Monitoring Deployment

After running `terraform apply`, you can monitor the deployment:

### Check Terraform Outputs

```powershell
terraform output
```

This shows:
- WebUI URL: `http://<your-ip>:8080`
- SSH command to connect
- Commands to check deployment status

### SSH into Instance

```bash
ssh -i ollama-key.pem ubuntu@<your-ip>
```

### View Deployment Logs

```bash
# Watch logs in real-time
sudo tail -f /var/log/user-data.log

# Check deployment status
cat /home/ubuntu/deployment-status.txt
```

### Check Service Status

```bash
# Check if Ollama is running
sudo ss -tnlp | grep ollama

# Check if Open-WebUI container is running
sudo docker ps | grep open-webui

# Test Ollama API
curl http://localhost:11434/api/tags
```

## Troubleshooting

### Git Clone Fails

**Symptoms**: Deployment status shows `git_clone: failed`

**Solutions**:
1. Verify your repository URL is correct in `terraform.tfvars`
2. Ensure the repository is publicly accessible
3. Check `/var/log/user-data.log` for specific git errors

### Deployment Script Not Found

**Symptoms**: Error message "Deployment script not found at /home/ubuntu/deployment/ec2-deploy-ollama.sh"

**Solutions**:
1. Ensure `ec2-deploy-ollama.sh` is in the root of your repository
2. Verify the file was committed and pushed to git
3. Check the branch name is correct (default is "main")

### Installation Fails

**Symptoms**: Deployment status shows component failures

**Solutions**:
1. SSH into the instance
2. Check logs: `sudo tail -100 /var/log/user-data.log`
3. Manually run the script: `cd /home/ubuntu/deployment && ./ec2-deploy-ollama.sh install`

### WebUI Not Accessible

**Symptoms**: Cannot access `http://<ip>:8080`

**Solutions**:
1. Wait 5-10 minutes for deployment to complete
2. Check if container is running: `sudo docker ps`
3. Check security group allows port 8080
4. Verify instance has public IP

## Configuration Options

### Change AI Model

Edit `terraform.tfvars`:

```hcl
default_model = "2"  # Options: 1-6
```

Models:
- 1 = deepseek-r1:8b (recommended, ~4.9GB)
- 2 = deepseek-r1:14b (~8.9GB)
- 3 = deepseek-r1:32b (~20GB)
- 4 = llama3.2:3b (~2GB)
- 5 = llama3.2:8b (~4.7GB)
- 6 = qwen2.5:7b (~4.7GB)

### Use Different Branch

Edit `terraform.tfvars`:

```hcl
git_branch = "develop"  # Or any branch name
```

### Use Private Repository (SSH)

1. Generate SSH key on your local machine
2. Add public key to GitHub/GitLab
3. Update `terraform.tfvars`:

```hcl
git_repo_url = "git@github.com:YOUR-USERNAME/YOUR-REPO.git"
```

4. Add SSH key to EC2 instance (requires additional Terraform configuration)

## Files Modified

- ✅ `terraform.tfvars` - Added git repository configuration
- ✅ `terraform.tfvars.example` - Added git repository configuration
- ✅ `user-data.sh.tpl` - Already configured correctly
- ✅ `terraform-ec2.tf` - Already configured correctly
- ✅ `ec2-deploy-ollama.sh` - Already has idempotent installation logic

## Next Steps

1. **Update `terraform.tfvars`** with your actual git repository URL
2. **Push your code** to the git repository
3. **Run deployment**: `.\deploy.ps1`
4. **Wait 5-10 minutes** for installation to complete
5. **Access WebUI** at the URL shown in Terraform outputs

## Support

If you encounter issues:
1. Check `/var/log/user-data.log` on the EC2 instance
2. Check `/home/ubuntu/deployment-status.txt` for component status
3. Review the troubleshooting section above
4. Ensure your repository is accessible and contains the deployment script
