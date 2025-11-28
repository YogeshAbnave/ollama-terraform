# ⚡ GitOps Quick Start - 3 Steps to Automated Deployment

## Setup in 3 Minutes

### Step 1: Add AWS Credentials to GitHub

1. Go to your repository on GitHub
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Add two secrets:

```
Name: AWS_ACCESS_KEY_ID
Value: <your-aws-access-key>

Name: AWS_SECRET_ACCESS_KEY
Value: <your-aws-secret-key>
```

**Don't have AWS credentials?**
```bash
# Check existing credentials
cat ~/.aws/credentials

# Or create new IAM user in AWS Console
# IAM → Users → Create → Attach: AmazonEC2FullAccess, AmazonVPCFullAccess
```

### Step 2: Push Workflow Files

```bash
# Add workflow files
git add .github/workflows/

# Commit
git commit -m "Add GitHub Actions workflows"

# Push to trigger deployment
git push origin main
```

### Step 3: Watch It Deploy!

1. Go to **Actions** tab in GitHub
2. Watch the deployment progress
3. After completion, check the commit comment for WebUI URL
4. Wait 10 minutes total, then access your WebUI!

---

## That's It! 🎉

Now every time you push code:
- ✅ GitHub Actions automatically deploys
- ✅ EC2 instance created
- ✅ Software installed
- ✅ WebUI URL in commit comment

---

## Quick Commands

### Deploy Changes
```bash
git add .
git commit -m "Update"
git push origin main
# ✨ Automatic deployment!
```

### Manual Deploy
1. Go to **Actions** tab
2. Click **Deploy to AWS EC2**
3. Click **Run workflow**

### Destroy Infrastructure
1. Go to **Actions** tab
2. Click **Destroy AWS Infrastructure**
3. Type `destroy` to confirm
4. Click **Run workflow**

---

## Monitoring

### View Deployment Status
- Go to **Actions** tab
- Click latest workflow run
- View real-time logs

### Get WebUI URL
- Check commit comment (auto-posted)
- Or download `deployment-info` artifact

### Check Installation Progress
```bash
# Get instance IP from Actions output
ssh -i ollama-key.pem ubuntu@<instance-ip> 'sudo tail -f /var/log/user-data.log'
```

---

## Customization (Optional)

### Change Instance Type

1. Go to **Settings** → **Secrets and variables** → **Actions** → **Variables**
2. Add variable:
   - Name: `INSTANCE_TYPE`
   - Value: `t3.2xlarge` (or any instance type)

### Change AI Model

1. Add variable:
   - Name: `DEFAULT_MODEL`
   - Value: `2` (for deepseek-r1:14b)

Models:
- `1` = deepseek-r1:8b (default)
- `2` = deepseek-r1:14b
- `3` = deepseek-r1:32b
- `4` = llama3.2:3b
- `5` = llama3.2:8b
- `6` = qwen2.5:7b

---

## Troubleshooting

### Workflow Fails
- Check AWS credentials are correct
- Verify IAM permissions
- Check workflow logs in Actions tab

### WebUI Not Accessible
- Wait full 10 minutes for installation
- Check commit comment for correct URL
- SSH in and check logs

### Need Help?
- See `GITHUB-ACTIONS-SETUP.md` for detailed guide
- See `TROUBLESHOOTING.md` for common issues
- Check workflow logs in Actions tab

---

## Complete Documentation

- **`GITHUB-ACTIONS-SETUP.md`** - Complete setup guide
- **`WORKFLOW.md`** - Manual deployment workflows
- **`TROUBLESHOOTING.md`** - Troubleshooting guide

---

## Success Indicators

You know it's working when:

✅ Workflow completes in Actions tab
✅ Commit has auto-comment with WebUI URL
✅ Can download deployment-info artifact
✅ After 10 minutes, WebUI is accessible
✅ Can register user and chat with AI

---

## Your GitOps Workflow

```
Edit Code → Commit → Push → GitHub Actions → AWS Deploy → WebUI Ready!
```

**That's it! Fully automated!** 🚀

---

## Next Steps

1. ✅ Add AWS credentials to GitHub secrets
2. ✅ Push workflow files
3. ✅ Watch Actions tab
4. ✅ Get WebUI URL from commit comment
5. ✅ Access your AI assistant!

**Welcome to automated deployments!** 🎊
