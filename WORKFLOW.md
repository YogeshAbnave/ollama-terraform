# 🔄 Automated Deployment Workflow

## The Simplest Way to Deploy

### One Command Deployment:

```powershell
.\auto-deploy.ps1
```

That's it! This single command will:
1. ✅ Verify your configuration
2. ✅ Commit and push your code to GitHub
3. ✅ Deploy infrastructure to AWS
4. ✅ Show you the WebUI URL
5. ✅ Offer to monitor deployment

---

## Usage Examples

### Basic Deployment (Default)

```powershell
# Commits with default message, pushes, and deploys
.\auto-deploy.ps1
```

### Custom Commit Message

```powershell
# Use your own commit message
.\auto-deploy.ps1 -CommitMessage "Add new features"
```

### Fresh Deployment (Destroy First)

```powershell
# Destroys existing infrastructure, then deploys fresh
.\auto-deploy.ps1 -DestroyFirst
```

### Skip Git Push (Code Already on GitHub)

```powershell
# Only deploy, don't push code
.\auto-deploy.ps1 -SkipGitPush
```

### Skip Verification (Faster)

```powershell
# Skip configuration verification
.\auto-deploy.ps1 -SkipVerification
```

### Combined Options

```powershell
# Destroy first, custom message, skip verification
.\auto-deploy.ps1 -DestroyFirst -CommitMessage "Major update" -SkipVerification
```

---

## Complete Workflow

### Daily Development Workflow:

```powershell
# 1. Make changes to your code
code ec2-deploy-ollama.sh

# 2. Test locally (optional)
# ... your tests ...

# 3. Deploy everything automatically
.\auto-deploy.ps1 -CommitMessage "Improved installation"

# 4. Wait 10 minutes

# 5. Access your WebUI!
```

### Update Existing Deployment:

```powershell
# Make changes
# ... edit files ...

# Destroy old and deploy fresh
.\auto-deploy.ps1 -DestroyFirst -CommitMessage "Update configuration"
```

### Quick Redeploy (Code Already Pushed):

```powershell
# If code is already on GitHub
.\auto-deploy.ps1 -SkipGitPush -DestroyFirst
```

---

## What Happens Automatically

### On Your Machine:

1. **Configuration Check** ✓
   - Verifies Terraform installed
   - Verifies AWS CLI installed
   - Checks required files exist
   - Validates terraform.tfvars

2. **Git Operations** ✓
   - Stages all changes (`git add .`)
   - Commits with your message
   - Pushes to GitHub (`git push origin main`)

3. **Infrastructure Deployment** ✓
   - Runs Terraform init
   - Applies Terraform configuration
   - Creates EC2 instance
   - Configures security groups
   - Assigns public IP

4. **Information Display** ✓
   - Shows instance IP
   - Shows WebUI URL
   - Saves URL to file
   - Offers monitoring options

### On EC2 Instance (Automatic):

1. **System Setup** ✓
   - Boots Ubuntu 22.04
   - Waits for cloud-init
   - Updates packages
   - Installs git

2. **Repository Clone** ✓
   - Clones from GitHub
   - Sets file permissions
   - Makes scripts executable

3. **Software Installation** ✓
   - Installs Ollama
   - Installs Docker
   - Downloads AI model
   - Starts Open-WebUI

4. **Logging & Status** ✓
   - Logs to `/var/log/user-data.log`
   - Creates status file
   - Updates MOTD

---

## Monitoring Deployment

### Option 1: Quick Status Check

```powershell
# Wait a minute for instance to boot
Start-Sleep -Seconds 60

# Check status
.\check-user-data.ps1
```

### Option 2: Watch Logs Live

```powershell
# Get instance IP
$IP = terraform output -raw instance_public_ip

# Watch logs in real-time
ssh -i ollama-key.pem ubuntu@$IP 'sudo tail -f /var/log/user-data.log'
```

### Option 3: Automated Monitoring

The `auto-deploy.ps1` script will ask if you want to check status automatically!

---

## Troubleshooting

### If Deployment Fails

```powershell
# Check what went wrong
.\check-user-data.ps1

# View detailed logs
$IP = terraform output -raw instance_public_ip
ssh -i ollama-key.pem ubuntu@$IP 'sudo cat /var/log/user-data.log'

# See troubleshooting guide
# Read TROUBLESHOOTING.md
```

### If Git Push Fails

```powershell
# Check git status
git status

# Check remote
git remote -v

# Try manual push
git push origin main

# If successful, deploy without push
.\auto-deploy.ps1 -SkipGitPush
```

### If You Need Fresh Start

```powershell
# Complete cleanup and redeploy
terraform destroy -auto-approve
Start-Sleep -Seconds 120
.\auto-deploy.ps1
```

---

## Alternative Workflows

### Manual Step-by-Step:

```powershell
# 1. Verify configuration
.\verify-config.ps1

# 2. Push code
git add .
git commit -m "Update"
git push origin main

# 3. Deploy
.\deploy.ps1

# 4. Monitor
.\check-user-data.ps1
```

### Using Terraform Directly:

```powershell
# Push code first
git push origin main

# Then deploy
terraform init
terraform plan
terraform apply -auto-approve

# Get URL
terraform output webui_url
```

---

## Configuration Files

### Files You Can Edit:

- **`terraform.tfvars`** - Your deployment configuration
  - Change instance type
  - Change AI model
  - Change region
  - Change storage size

- **`ec2-deploy-ollama.sh`** - Installation script
  - Modify installation steps
  - Add custom software
  - Change configuration

- **`user-data.sh.tpl`** - Bootstrap script
  - Modify initialization
  - Add pre-installation steps
  - Change logging

### Files You Shouldn't Edit:

- **`terraform-ec2.tf`** - Infrastructure definition (unless you know Terraform)
- **`deploy.ps1`** - Deployment script (unless you need custom logic)
- **`verify-config.ps1`** - Verification script

---

## Best Practices

### 1. Always Verify Before Deploy

```powershell
.\verify-config.ps1
```

### 2. Use Meaningful Commit Messages

```powershell
.\auto-deploy.ps1 -CommitMessage "Fix Ollama installation issue"
```

### 3. Test Changes Locally First

```bash
# Test your script locally before deploying
bash ec2-deploy-ollama.sh install
```

### 4. Monitor First Deployment

```powershell
# Watch logs on first deploy to catch issues early
.\auto-deploy.ps1
# Then immediately:
.\check-user-data.ps1
```

### 5. Destroy When Not Using

```powershell
# Save costs by destroying when not needed
terraform destroy -auto-approve
```

---

## Quick Reference

### Deploy Commands:

```powershell
# Simple deploy
.\auto-deploy.ps1

# Fresh deploy
.\auto-deploy.ps1 -DestroyFirst

# Custom message
.\auto-deploy.ps1 -CommitMessage "Your message"

# Skip git
.\auto-deploy.ps1 -SkipGitPush

# Fast deploy
.\auto-deploy.ps1 -SkipVerification
```

### Monitoring Commands:

```powershell
# Check status
.\check-user-data.ps1

# Watch logs
ssh -i ollama-key.pem ubuntu@$(terraform output -raw instance_public_ip) 'sudo tail -f /var/log/user-data.log'

# Get URL
terraform output webui_url

# Open browser
Start-Process $(terraform output -raw webui_url)
```

### Management Commands:

```powershell
# Destroy
terraform destroy -auto-approve

# Refresh state
terraform refresh

# Show outputs
terraform output

# Verify config
.\verify-config.ps1
```

---

## Success Indicators

You know it's working when:

✅ `auto-deploy.ps1` completes without errors
✅ Terraform shows "Apply complete!"
✅ WebUI URL is displayed
✅ `check-user-data.ps1` shows services installing
✅ After 10 minutes, WebUI is accessible
✅ Can register user and chat with AI

---

## Timeline

- **0:00** - Run `.\auto-deploy.ps1`
- **0:30** - Code pushed to GitHub
- **1:00** - Terraform starts creating infrastructure
- **3:00** - EC2 instance boots
- **4:00** - Git clone and installation begins
- **5:00** - Ollama and Docker installing
- **8:00** - AI model downloading
- **10:00** - ✅ WebUI ready!

---

## Support

If you encounter issues:

1. **Check status**: `.\check-user-data.ps1`
2. **View logs**: See TROUBLESHOOTING.md
3. **Verify config**: `.\verify-config.ps1`
4. **Fresh start**: `terraform destroy -auto-approve && .\auto-deploy.ps1`

---

## Summary

**The workflow is now completely automated!**

Just run:
```powershell
.\auto-deploy.ps1
```

And everything happens automatically:
- ✅ Code pushed to GitHub
- ✅ Infrastructure deployed
- ✅ Software installed
- ✅ WebUI ready in 10 minutes

**That's it! Push and go!** 🚀
