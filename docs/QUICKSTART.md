# Quick Start Guide

## 3-Step Setup

### 1. Add AWS Credentials to GitHub Secrets

1. Go to **Settings** → **Secrets and variables** → **Actions**
2. Add these secrets:
   - `AWS_ACCESS_KEY_ID` - Your AWS access key
   - `AWS_SECRET_ACCESS_KEY` - Your AWS secret key

### 2. Push to GitHub

```bash
git push origin main
```

### 3. Access Your WebUI

- Go to **Actions** tab and watch deployment
- After completion, check workflow summary for WebUI URL
- Wait 15-20 minutes for installation
- Access WebUI at `http://<your-ip>:8080`

---

## Troubleshooting

### WebUI Not Accessible

1. Wait 20 minutes for installation
2. Check workflow logs in Actions tab
3. SSH and check logs:
   ```bash
   ssh -i ollama-key.pem ubuntu@<ip>
   sudo tail -f /var/log/user-data.log
   ```
4. Run fix script:
   ```bash
   ssh -i ollama-key.pem ubuntu@<ip>
   curl -sSL https://raw.githubusercontent.com/YogeshAbnave/ollama-terraform/main/scripts/fix-deployment.sh | sudo bash
   ```

### Workflow Fails

- Verify AWS credentials are correct
- Check IAM permissions (EC2, VPC, CloudWatch)
- Ensure default VPC exists in region
- Review workflow logs in Actions tab

---

## Customization

Add these as GitHub Variables (Settings → Secrets and variables → Actions → Variables):

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

## Monitoring

### View Deployment Status
- Go to **Actions** tab
- Click latest workflow run
- View real-time logs

### SSH into Instance
```bash
ssh -i ollama-key.pem ubuntu@<instance-ip>

# View installation logs
sudo tail -f /var/log/user-data.log

# Check deployment status
cat /home/ubuntu/deployment-status.txt
```

---

## Destroy Infrastructure

1. Go to **Actions** tab
2. Click **Destroy AWS Infrastructure**
3. Type `destroy` to confirm
4. Click **Run workflow**
