# 🚀 Ollama + Open-WebUI AWS Deployment

[![Deploy Status](https://github.com/YogeshAbnave/ollama-terraform/actions/workflows/deploy-to-aws.yml/badge.svg)](https://github.com/YogeshAbnave/ollama-terraform/actions/workflows/deploy-to-aws.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Terraform](https://img.shields.io/badge/Terraform-1.6+-purple.svg)](https://www.terraform.io/)
[![AWS](https://img.shields.io/badge/AWS-EC2-orange.svg)](https://aws.amazon.com/ec2/)

Automated deployment of Ollama AI with Open-WebUI on AWS EC2 using GitHub Actions and Terraform.

## ⚡ Quick Start

### 1. Add AWS Credentials to GitHub

1. Go to your repository → **Settings** → **Secrets and variables** → **Actions**
2. Add these secrets:
   - `AWS_ACCESS_KEY_ID` - Your AWS access key
   - `AWS_SECRET_ACCESS_KEY` - Your AWS secret key

### 2. Push to GitHub

```bash
git push origin main
```

### 3. Access Your WebUI

1. Go to **Actions** tab and watch deployment
2. After completion, check workflow summary for WebUI URL
3. Wait 15-20 minutes for installation
4. Access WebUI at `http://<your-ip>:8080`

---

## 📋 What Gets Deployed

- **EC2 Instance** (Ubuntu 22.04, t3.xlarge)
- **Ollama** (AI model runtime)
- **Docker** (Container runtime)
- **AI Model** (deepseek-r1:8b, ~4.9GB)
- **Open-WebUI** (Web interface on port 8080)
- **RAG Support** (Optional - upload documents for AI to reference)

**Total Time:** ~15-20 minutes

---

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

---

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

---

## 📁 Project Structure

```
.
├── .github/workflows/
│   ├── deploy-to-aws.yml          # Main deployment workflow
│   └── destroy-infrastructure.yml  # Destruction workflow
├── terraform/
│   ├── terraform-ec2.tf            # Infrastructure definition
│   ├── user-data.sh.tpl            # EC2 initialization script
│   └── terraform.tfvars.example    # Configuration template
├── scripts/
│   ├── fix-deployment.sh           # Manual fix script (if needed)
│   └── kernel-tuning.sh            # Kernel optimization script
├── .kiro/specs/                    # Kiro specifications
├── README.md                       # This file
└── LICENSE                         # MIT License
```

---

## 🔍 Monitoring

### View Deployment Status

- Go to **Actions** tab
- Click latest workflow run
- View real-time logs
- Check workflow summary for WebUI URL

### SSH into Instance

```bash
# Get instance IP from Actions output
ssh -i ollama-key.pem ubuntu@<instance-ip>

# View installation logs
sudo tail -f /var/log/user-data.log

# Check deployment status
cat /home/ubuntu/deployment-status.txt
```

---

## 🛠️ Troubleshooting

### WebUI Not Accessible

1. **Wait 20 minutes** - Installation takes time
2. **Check workflow logs** - Look for errors in Actions tab
3. **SSH and check logs:**
   ```bash
   ssh -i ollama-key.pem ubuntu@<ip>
   sudo tail -f /var/log/user-data.log
   ```
4. **Run fix script:**
   ```bash
   ssh -i ollama-key.pem ubuntu@<ip>
   curl -sSL https://raw.githubusercontent.com/YogeshAbnave/ollama-terraform/main/fix-deployment.sh | sudo bash
   ```

### Workflow Fails

- Verify AWS credentials are correct
- Check IAM permissions (EC2, VPC, CloudWatch)
- Ensure default VPC exists in region
- Review workflow logs in Actions tab

### Need More Help?

- Check workflow logs in Actions tab
- Review deployment logs via SSH
- Run the fix script: `scripts/fix-deployment.sh`
- Check GitHub Issues for common problems

---

## 🔐 Security

- AWS credentials stored as GitHub secrets
- SSH access configurable via `ALLOWED_SSH_CIDR`
- Security group allows ports: 22 (SSH), 8080 (WebUI), 11434 (Ollama)

---

## 💰 Cost Estimate

- **t3.xlarge:** ~$0.17/hour (~$120/month if running 24/7)
- **Storage (50GB):** ~$5/month
- **Data transfer:** Varies

**Tip:** Destroy infrastructure when not in use to save costs!

---

## 🎉 Success Indicators

You know it's working when:

✅ Workflow completes in Actions tab  
✅ Can download deployment-info artifact  
✅ After 20 minutes, WebUI is accessible  
✅ Can register user and chat with AI  

---

## 🚀 Your GitOps Workflow

```
Edit Code → Commit → Push → GitHub Actions → AWS Deploy → WebUI Ready!
```

**Fully automated deployment!** 🎊

---

## 🤝 Contributing

Contributions are welcome! Feel free to:
- Open issues for bugs or feature requests
- Submit pull requests with improvements
- Share your deployment experiences

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [Ollama](https://ollama.ai/) - AI model runtime
- [Open-WebUI](https://github.com/open-webui/open-webui) - Web interface
- [Terraform](https://www.terraform.io/) - Infrastructure as Code
- [GitHub Actions](https://github.com/features/actions) - CI/CD automation

## 🔥 RAG (Retrieval-Augmented Generation)

Want to upload documents and have AI reference them? Enable RAG features:

```bash
# SSH into your EC2 instance
ssh -i ollama-key.pem ubuntu@<your-ip>

# Run the RAG setup script
curl -sSL https://raw.githubusercontent.com/YogeshAbnave/ollama-terraform/main/scripts/enable-rag.sh | sudo bash
```

**Features:**
- 📄 Upload PDF, TXT, MD, DOCX documents
- 🔍 Semantic search with vector database
- 💡 AI answers grounded in your documents
- 📚 Source attribution in responses

**Setup Time:** ~2-3 minutes

**Documentation:**
- 📘 [RAG Setup Guide](docs/RAG-SETUP.md) - Complete setup instructions
- 📄 [How to Upload PDFs](docs/HOW-TO-UPLOAD-PDFS.md) - Step-by-step PDF upload guide
- 💬 [How to Query RAG](docs/HOW-TO-QUERY-RAG.md) - Ask questions and retrieve data
- 📋 [RAG Cheat Sheet](docs/RAG-CHEAT-SHEET.md) - Quick query templates
- ⚡ [Quick Reference](docs/RAG-QUICK-REFERENCE.md) - Commands and troubleshooting

---

## 📧 Support

- 📖 [Quick Start Guide](docs/QUICKSTART.md)
- 🚀 [RAG Setup Guide](docs/RAG-SETUP.md)
- 🐛 [Issue Tracker](https://github.com/YogeshAbnave/ollama-terraform/issues)
- 💬 [Discussions](https://github.com/YogeshAbnave/ollama-terraform/discussions)

---

**Made with ❤️ for automated AI deployments**

⭐ Star this repo if you find it helpful!
