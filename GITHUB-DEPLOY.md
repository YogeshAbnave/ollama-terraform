# 🚀 Deploy with GitHub (One Push = Production URL)

## ✅ Yes! Push to GitHub = Automatic Deployment

When you push this code to GitHub, it will **automatically**:
1. ✅ Deploy infrastructure
2. ✅ Give you production URL
3. ✅ Save URL as artifact
4. ✅ Show URL in workflow summary

---

## 📋 Setup (One-Time)

### Step 1: Create GitHub Repository

```bash
git init
git add .
git commit -m "Initial commit"
git branch -M main
git remote add origin https://github.com/YOUR-USERNAME/YOUR-REPO.git
git push -u origin main
```

### Step 2: Add GitHub Secrets

Go to your repo → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**

Add these 3 secrets:

| Secret Name | Value | Where to Get |
|-------------|-------|--------------|
| `AWS_ACCESS_KEY_ID` | Your AWS access key | AWS IAM Console |
| `AWS_SECRET_ACCESS_KEY` | Your AWS secret key | AWS IAM Console |
| `AWS_REGION` | `us-east-1` | Your preferred region |

**That's it!** Setup complete.

---

## 🎯 How to Deploy

### Option 1: Push to Main (Automatic)

```bash
git add .
git commit -m "Deploy"
git push
```

**Done!** GitHub Actions will:
- Deploy in 3 minutes
- Show production URL in workflow
- Save URL as downloadable artifact

### Option 2: Manual Trigger

1. Go to **Actions** tab
2. Click **Auto Deploy on Push**
3. Click **Run workflow**
4. Click **Run workflow** button

---

## 📊 Where to Find Production URL

### Method 1: Workflow Summary

1. Go to **Actions** tab
2. Click on latest workflow run
3. See **Deployment Summary** at bottom:

```
🚀 Deployment Summary

Production URL: http://34.232.84.45:8080

⏳ Status: Installation in progress (5-10 minutes)

📝 Note: First user to register becomes admin
```

### Method 2: Download Artifact

1. Go to **Actions** tab
2. Click on latest workflow run
3. Scroll to **Artifacts** section
4. Download **production-url**
5. Open `PRODUCTION-URL.txt`

### Method 3: Workflow Logs

1. Go to **Actions** tab
2. Click on latest workflow run
3. Click **Get Production URL** step
4. See the URL in logs:

```
============================================================

  🎉 DEPLOYMENT COMPLETE!

  Production URL:
  http://34.232.84.45:8080

============================================================
```

---

## ⏱️ Timeline

```
0:00 - Push code to GitHub
0:10 - Workflow starts
3:00 - ✅ Production URL available!
      (Check Actions tab)
      
3:00-10:00 - Installation in background
            
10:00 - ✅ Ready to use!
```

---

## 🔄 Workflow Features

The `auto-deploy.yml` workflow:

✅ **Triggers on:**
- Push to `main` branch
- Manual trigger (workflow_dispatch)

✅ **Automatically:**
- Gets your IP address
- Creates SSH key if needed
- Configures Terraform
- Deploys infrastructure
- Outputs production URL

✅ **Provides URL in:**
- Workflow summary
- Downloadable artifact
- Workflow logs

---

## 💡 Pro Tips

### 1. Watch Deployment Live

```bash
# In your terminal
git push

# Then immediately go to:
# https://github.com/YOUR-USERNAME/YOUR-REPO/actions
```

### 2. Get URL Immediately

After push, the URL appears in ~3 minutes in the workflow summary.

### 3. Multiple Deployments

Each push creates a **new** deployment. To avoid multiple instances:

```bash
# Destroy old instance first
terraform destroy

# Then push new code
git push
```

---

## 🗑️ Destroy Deployment

### Option 1: Locally

```powershell
terraform destroy
```

### Option 2: Add Destroy Workflow

Create `.github/workflows/destroy.yml`:

```yaml
name: Destroy Infrastructure

on:
  workflow_dispatch:

jobs:
  destroy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: hashicorp/setup-terraform@v2
      - name: Configure AWS
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ secrets.AWS_REGION }}
      - run: terraform init
      - run: terraform destroy -auto-approve
```

---

## 📝 Example Workflow Output

```
Run Get Production URL
============================================================

  🎉 DEPLOYMENT COMPLETE!

  Production URL:
  http://54.123.45.67:8080

============================================================

⏳ Installation in progress (5-10 minutes)
📝 First user to register becomes admin

✅ URL saved to PRODUCTION-URL.txt
✅ Artifact uploaded
```

---

## ✅ Summary

| Action | Result | Time |
|--------|--------|------|
| **Push code** | Workflow starts | Instant |
| **Wait** | Infrastructure deploys | 3 min |
| **Check Actions** | Get production URL | 3 min |
| **Open URL** | Access AI assistant | 10 min |

---

## 🆘 Troubleshooting

### Workflow Fails

**Check:**
1. Secrets are configured correctly
2. AWS credentials have EC2 permissions
3. Region is valid

### Can't Find URL

**Look in:**
1. Workflow summary (bottom of workflow page)
2. Artifacts section (download production-url)
3. "Get Production URL" step logs

### Multiple Instances Running

```bash
# List all instances
aws ec2 describe-instances --filters "Name=tag:Project,Values=ollama-webui"

# Destroy locally
terraform destroy
```

---

**Ready?** Just push your code and get the production URL in 3 minutes! 🚀
