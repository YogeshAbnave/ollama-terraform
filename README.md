# 🚀 Ollama + Open-WebUI EC2 Deployment

Deploy your own private AI assistant (like ChatGPT) on AWS EC2 in 10 minutes.

## ⚡ Three Ways to Deploy

### Option 1: Push to GitHub (Easiest) ⭐

```bash
git push
```

**That's it!** GitHub Actions will:
- ✅ Deploy automatically (3 minutes)
- ✅ Show production URL in Actions tab
- ✅ Save URL as downloadable artifact

**Setup:** [GITHUB-DEPLOY.md](./GITHUB-DEPLOY.md)

---

### Option 2: Double-Click (Windows)

1. **Double-click** `deploy.bat`
2. Wait 3 minutes
3. Browser opens with production URL!

---

### Option 3: PowerShell

```powershell
.\deploy.ps1
```

---

### Option 4: Manual

```powershell
terraform init
terraform apply
terraform output webui_url
```

---

## 📚 Documentation

**Everything you need is in:** [COMPLETE-GUIDE.md](./COMPLETE-GUIDE.md)

Includes:
- ✅ Detailed setup instructions
- ✅ Windows-specific guide
- ✅ Troubleshooting
- ✅ Cost optimization
- ✅ Management commands
- ✅ Security best practices

---

## 💰 Cost

| Instance | Cost/Month | Best For |
|----------|------------|----------|
| t3.large | $60 | Testing |
| **t3.xlarge** ⭐ | **$120** | **Recommended** |
| c5.2xlarge | $250 | High performance |

**Save 70-90% with Spot Instances!**

---

## 🛠️ Quick Commands

```powershell
# Get info
terraform output

# SSH into instance
ssh -i ollama-key.pem ubuntu@<IP>

# Destroy everything
terraform destroy
```

---

## 📁 Project Files

- `ec2-deploy-ollama.sh` - Main deployment script (runs on EC2)
- `user-data.sh.tpl` - EC2 initialization script template
- `terraform-ec2.tf` - Infrastructure configuration
- `terraform.tfvars.example` - Configuration template
- `deploy.ps1` - PowerShell deployment script
- `deploy.bat` - Windows batch deployment script
- `COMPLETE-GUIDE.md` - Full documentation
- `.github/workflows/deploy.yml` - CI/CD automation

---

## 🎯 What You Get

- ✅ **Ollama** - Run AI models locally
- ✅ **Open-WebUI** - ChatGPT-like interface
- ✅ **deepseek-r1:8b** - 8B parameter AI model (configurable)
- ✅ **Complete infrastructure** - VPC, security, monitoring
- ✅ **Automated deployment** - Git clone and install on boot
- ✅ **Idempotent installation** - Safe to run multiple times
- ✅ **Comprehensive logging** - Full deployment logs and status

---

## 🔧 Configuration

### Git Repository Setup

The deployment automatically clones your repository on EC2 boot. Update `terraform.tfvars`:

```hcl
git_repo_url  = "https://github.com/yourusername/your-repo.git"
git_branch    = "main"
default_model = "1"  # 1=deepseek-r1:8b (recommended)
```

### Deployment Status

After deployment, check status:

```powershell
# View deployment logs
terraform output deployment_log_command

# Check deployment status
terraform output deployment_status_command
```

Status file location: `/home/ubuntu/deployment-status.txt`

---

## 🆘 Need Help?

See [COMPLETE-GUIDE.md](./COMPLETE-GUIDE.md) for:
- Detailed instructions
- Troubleshooting
- Windows guide
- Cost optimization
- Management

---

**Made with ❤️ for the AI community**

**Time to deploy:** 10 minutes | **Difficulty:** Easy | **Cost:** From $60/month
