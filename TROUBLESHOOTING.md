# EC2 Auto-Deploy Troubleshooting Guide

## Quick Diagnostic

Run this script to check if user-data is executing:

```powershell
.\check-user-data.ps1
```

This will show you:
- ✓ If user-data log exists
- ✓ If repository was cloned
- ✓ If services are installed
- ✓ Current deployment status

---

## Common Issues and Solutions

### Issue 1: Repository Not Cloning

**Symptoms:**
- No `/home/ubuntu/deployment` directory
- User-data log shows git clone errors

**Causes:**
1. Git not installed on instance
2. Repository URL incorrect
3. Repository is private
4. Network connectivity issues

**Solutions:**

#### Solution 1A: Git Not Installed (FIXED)
The user-data script now automatically installs git before cloning.

#### Solution 1B: Check Repository URL
```powershell
# Verify your terraform.tfvars has correct URL
cat terraform.tfvars | Select-String "git_repo_url"

# Should show:
# git_repo_url = "https://github.com/YogeshAbnave/ollama-terraform.git"
```

#### Solution 1C: Make Repository Public
1. Go to https://github.com/YogeshAbnave/ollama-terraform
2. Settings → Danger Zone → Change visibility → Public

#### Solution 1D: Manual Clone Test
SSH into instance and test manually:
```bash
ssh -i ollama-key.pem ubuntu@<your-ip>

# Test git clone
git clone https://github.com/YogeshAbnave/ollama-terraform.git test-clone

# If successful, check what went wrong with auto-deploy
sudo cat /var/log/user-data.log
```

---

### Issue 2: User-Data Not Running

**Symptoms:**
- No `/var/log/user-data.log` file
- Nothing happens after instance boots

**Causes:**
1. User-data script has syntax errors
2. Cloud-init failed
3. Instance didn't receive user-data

**Solutions:**

#### Solution 2A: Check Cloud-Init Status
```bash
ssh -i ollama-key.pem ubuntu@<your-ip>

# Check cloud-init status
cloud-init status --long

# View cloud-init logs
sudo cat /var/log/cloud-init-output.log
```

#### Solution 2B: Verify User-Data Was Passed
```bash
# On the EC2 instance
curl http://169.254.169.254/latest/user-data

# Should show your user-data script
```

#### Solution 2C: Force Re-Run User-Data
If you need to re-run the deployment:
```bash
# SSH into instance
ssh -i ollama-key.pem ubuntu@<your-ip>

# Manually run the deployment
cd /home/ubuntu
git clone https://github.com/YogeshAbnave/ollama-terraform.git deployment
cd deployment
chmod +x ec2-deploy-ollama.sh
echo "1" | ./ec2-deploy-ollama.sh install
```

---

### Issue 3: Deployment Script Fails

**Symptoms:**
- Repository cloned successfully
- But Ollama/Docker not installed
- Deployment status shows failures

**Causes:**
1. Snap package installation fails
2. Insufficient disk space
3. Network issues downloading packages

**Solutions:**

#### Solution 3A: Check Disk Space
```bash
ssh -i ollama-key.pem ubuntu@<your-ip>

# Check available space
df -h

# Should have at least 20GB free
```

#### Solution 3B: Check Snap Status
```bash
# Check if snap is working
sudo snap list

# If snap has issues, restart it
sudo systemctl restart snapd
```

#### Solution 3C: Manual Installation
```bash
# SSH into instance
ssh -i ollama-key.pem ubuntu@<your-ip>

# Install Ollama manually
sudo snap install ollama

# Install Docker manually
sudo snap install docker

# Check if they work
ollama --version
docker --version
```

---

### Issue 4: Services Installed But Not Running

**Symptoms:**
- Ollama and Docker installed
- But Open-WebUI not accessible
- Port 8080 not responding

**Causes:**
1. Container failed to start
2. Ollama service not running
3. Port conflict

**Solutions:**

#### Solution 4A: Check Service Status
```bash
ssh -i ollama-key.pem ubuntu@<your-ip>

# Check if Ollama is running
sudo ss -tnlp | grep 11434

# Check if Docker container is running
sudo docker ps

# Check container logs
sudo docker logs open-webui
```

#### Solution 4B: Restart Services
```bash
# Restart Ollama
sudo snap restart ollama

# Restart Docker container
sudo docker restart open-webui

# Or recreate container
sudo docker rm -f open-webui
cd /home/ubuntu/deployment
./ec2-deploy-ollama.sh install
```

#### Solution 4C: Check Security Group
```powershell
# On your local machine
# Verify port 8080 is open
terraform output security_group_id

# Check in AWS Console:
# EC2 → Security Groups → Your SG → Inbound Rules
# Should have: TCP 8080 from 0.0.0.0/0
```

---

### Issue 5: Can't Access WebUI

**Symptoms:**
- Everything installed and running
- But can't access http://<ip>:8080

**Causes:**
1. Wrong IP address
2. Security group blocking
3. Container not bound to correct port

**Solutions:**

#### Solution 5A: Verify Correct IP
```powershell
# Get the correct public IP
terraform output instance_public_ip

# Try accessing
Start-Process "http://$(terraform output -raw instance_public_ip):8080"
```

#### Solution 5B: Test from Instance
```bash
ssh -i ollama-key.pem ubuntu@<your-ip>

# Test locally
curl http://localhost:8080

# If this works but external doesn't, it's a security group issue
```

#### Solution 5C: Check Container Port Binding
```bash
# Check what ports container is using
sudo docker port open-webui

# Should show: 8080/tcp -> 0.0.0.0:8080

# If not, recreate container with correct ports
sudo docker rm -f open-webui
sudo docker run -d \
  --network host \
  --name open-webui \
  -p 3000:8080 \
  -e OLLAMA_BASE_URL=http://localhost:11434 \
  -v open-webui:/app/backend/data \
  --restart always \
  ghcr.io/open-webui/open-webui:main
```

---

## Diagnostic Commands

### Check Everything at Once
```bash
ssh -i ollama-key.pem ubuntu@<your-ip> << 'EOF'
echo "=== User-Data Log ==="
sudo tail -50 /var/log/user-data.log
echo ""
echo "=== Deployment Status ==="
cat /home/ubuntu/deployment-status.txt
echo ""
echo "=== Repository ==="
ls -la /home/ubuntu/deployment/
echo ""
echo "=== Services ==="
ollama --version
docker --version
sudo docker ps
echo ""
echo "=== Ports ==="
sudo ss -tnlp | grep -E "11434|8080"
EOF
```

### Watch Logs in Real-Time
```bash
ssh -i ollama-key.pem ubuntu@<your-ip> 'sudo tail -f /var/log/user-data.log'
```

### Check Cloud-Init Progress
```bash
ssh -i ollama-key.pem ubuntu@<your-ip> 'cloud-init status --wait && echo "Cloud-init complete!"'
```

---

## Force Complete Re-Deployment

If nothing works, destroy and recreate:

```powershell
# Destroy current infrastructure
terraform destroy -auto-approve

# Wait 2 minutes for cleanup

# Re-deploy
terraform apply -auto-approve

# Wait 10 minutes for deployment

# Check status
.\check-user-data.ps1
```

---

## Getting Help

If you're still stuck:

1. **Collect logs:**
   ```bash
   ssh -i ollama-key.pem ubuntu@<your-ip> 'sudo tar -czf logs.tar.gz /var/log/user-data.log /var/log/cloud-init*.log /home/ubuntu/deployment-status.txt'
   scp -i ollama-key.pem ubuntu@<your-ip>:logs.tar.gz .
   ```

2. **Check these files:**
   - `/var/log/user-data.log` - Main deployment log
   - `/var/log/cloud-init-output.log` - Cloud-init output
   - `/home/ubuntu/deployment-status.txt` - Deployment status
   - `terraform.tfvars` - Your configuration

3. **Verify configuration:**
   ```powershell
   .\verify-config.ps1
   ```

---

## Prevention Checklist

Before deploying:

- [ ] Repository URL is correct in `terraform.tfvars`
- [ ] Repository is public or has proper authentication
- [ ] `ec2-deploy-ollama.sh` exists in repository root
- [ ] Code is pushed to GitHub
- [ ] AWS credentials are configured
- [ ] SSH key pair exists or will be created
- [ ] Sufficient AWS quotas (VPC, EC2, etc.)

Run verification:
```powershell
.\verify-config.ps1
```

---

## Success Indicators

You know it's working when:

✓ `/var/log/user-data.log` exists and shows progress
✓ `/home/ubuntu/deployment/` directory exists
✓ `deployment-status.txt` shows all components as "success"
✓ `ollama --version` works
✓ `docker ps` shows open-webui container running
✓ Can access http://<ip>:8080 in browser
✓ Can register user and chat with AI model

---

## Quick Reference

```powershell
# Check deployment status
.\check-user-data.ps1

# View logs
ssh -i ollama-key.pem ubuntu@<ip> 'sudo tail -f /var/log/user-data.log'

# Get WebUI URL
terraform output webui_url

# Restart everything
ssh -i ollama-key.pem ubuntu@<ip> 'cd /home/ubuntu/deployment && ./ec2-deploy-ollama.sh cleanup'

# Full re-deploy
terraform destroy -auto-approve && terraform apply -auto-approve
```
