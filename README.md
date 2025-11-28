# 🚀 Ollama + Open-WebUI AWS Deployment

Automated deployment of Ollama AI with Open-WebUI on AWS EC2 using GitHub Actions.

## ⚡ Quick Start (3 Steps)

### 1. Add AWS Credentials to GitHub

1. Go to your repository → **Settings** → **Secrets and variables** → **Actions**
2. Add these secrets:
   - `AWS_ACCESS_KEY_ID` - Your AWS access key
   - `AWS_SECRET_ACCESS_KEY` - Your AWS secret key

### 2. Push to GitHub

```bash
git add .
git commit -m "Deploy to AWS"
git push origin main
```

### 3. Access Your WebUI

1. Go to **Actions** tab and watch deployment
2. After completion, check commit comment for WebUI URL
3. Wait 10 minutes for installation
4. Access WebUI at `http://<your-ip>:8080`

## 📋 What Gets Deployed

- **EC2 Instance** (Ubuntu 22.04, t3.xlarge)
- **Ollama** (AI model runtime)
- **Docker** (Container runtime)
- **AI Model** (deepseek-r1:8b, ~4.9GB)
- **Open-WebUI** (Web interface on port 8080)

**Total Time:** ~12 minutes

## 🎮 Usage

### Automatic Deployment

Every push to `main` branch automatically deploys:

```bash
git push origin main
# ✨ Automatic deployment starts!
```

### Manual Deployment

1. Go to **Actions** tab
2. Click **Deploy to AWS EC2**
3. Click **Run workflow**

### Destroy Infrastructure

1. Go to **Actions** tab
2. Click **Destroy AWS Infrastructure**
3. Type `destroy` to confirm
4. Click **Run workflow**

## ⚙️ Configuration (Optional)

Add these as GitHub Variables to customize:

| Variable | Default | Description |
|----------|---------|-------------|
| `INSTANCE_TYPE` | `t3.xlarge` | EC2 instance type |
| `STORAGE_SIZE` | `50` | Storage in GB |
| `DEFAULT_MODEL` | `1` | AI model (1-6) |

**AI Models:**
- `1` = deepseek-r1:8b (~4.9GB) - Recommended
- `2` = deepseek-r1:14b (~8.9GB)
- `3` = deepseek-r1:32b (~20GB)
- `4` = llama3.2:3b (~2GB)
- `5` = llama3.2:8b (~4.7GB)
- `6` = qwen2.5:7b (~4.7GB)

## 📁 Project Structure

```
.
├── .github/workflows/
│   ├── deploy-to-aws.yml          # Main deployment workflow
│   └── destroy-infrastructure.yml  # Destruction workflow
├── terraform-ec2.tf                # Infrastructure definition
├── user-data.sh.tpl                # EC2 initialization script
├── ec2-deploy-ollama.sh            # Software installation script
├── terraform.tfvars.example        # Configuration template
├── README.md                       # This file
├── GITHUB-ACTIONS-SETUP.md         # Detailed setup guide
├── GITOPS-QUICKSTART.md            # Quick start guide
└── TROUBLESHOOTING.md              # Troubleshooting guide
```

## 🔍 Monitoring

### View Deployment Status

- Go to **Actions** tab
- Click latest workflow run
- View real-time logs

### Get WebUI URL

- Check commit comment (auto-posted)
- Or download `deployment-info` artifact from workflow

### SSH into Instance

```bash
# Get instance IP from Actions output or commit comment
ssh -i ollama-key.pem ubuntu@<instance-ip>

# View installation logs
sudo tail -f /var/log/user-data.log

# Check deployment status
cat /home/ubuntu/deployment-status.txt
```

## 🛠️ Troubleshooting

### 🚨 WebUI Not Working? EMERGENCY FIX:

```bash
# 1. Get instance IP
terraform output instance_public_ip

# 2. SSH into instance
ssh -i ollama-key.pem ubuntu@<YOUR-IP>

# 3. Run fix script
curl -sSL https://raw.githubusercontent.com/YogeshAbnave/ollama-terraform/main/fix-deployment.sh | sudo bash

# 4. Access WebUI
# http://<YOUR-IP>:8080
```

**See `EMERGENCY-FIX.md` for detailed fix instructions!**

### Workflow Fails

- Verify AWS credentials are correct
- Check IAM permissions (EC2, VPC, CloudWatch)
- Review workflow logs in Actions tab

### WebUI Not Accessible

- Wait full 15 minutes for installation
- Run emergency fix script (see above)
- Check security group allows port 8080
- SSH in and check logs: `sudo tail -f /var/log/user-data.log`

### Need More Help?

- **`EMERGENCY-FIX.md`** - Quick fix for WebUI issues
- **`GITHUB-ACTIONS-SETUP.md`** - Detailed setup
- **`TROUBLESHOOTING.md`** - Common issues
- Check workflow logs in Actions tab

## 🔐 Security

- AWS credentials stored as GitHub secrets
- SSH access configurable via `ALLOWED_SSH_CIDR`
- Security group allows ports: 22 (SSH), 8080 (WebUI), 11434 (Ollama)

## 💰 Cost Estimate

- **t3.xlarge:** ~$0.17/hour (~$120/month if running 24/7)
- **Storage (50GB):** ~$5/month
- **Data transfer:** Varies

**Tip:** Destroy infrastructure when not in use to save costs!

## 📚 Documentation

- **`README.md`** - This file (quick reference)
- **`GITOPS-QUICKSTART.md`** - 3-minute quick start
- **`GITHUB-ACTIONS-SETUP.md`** - Complete setup guide
- **`TROUBLESHOOTING.md`** - Troubleshooting guide

## 🎉 Success Indicators

You know it's working when:

✅ Workflow completes in Actions tab  
✅ Commit has auto-comment with WebUI URL  
✅ Can download deployment-info artifact  
✅ After 10 minutes, WebUI is accessible  
✅ Can register user and chat with AI  

## 🚀 Your GitOps Workflow

```
Edit Code → Commit → Push → GitHub Actions → AWS Deploy → WebUI Ready!
```

**Fully automated deployment!** 🎊

## 📄 License

MIT License - Feel free to use and modify!

## 🤝 Contributing

Contributions welcome! Please open an issue or PR.

---

**Made with ❤️ for automated AI deployments**
