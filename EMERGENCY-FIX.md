# 🚨 EMERGENCY FIX - WebUI Not Working

## Quick Fix (2 Minutes)

### Step 1: Get Your Instance IP

```bash
# From your local machine
terraform output instance_public_ip
```

### Step 2: SSH into Instance

```bash
ssh -i ollama-key.pem ubuntu@<YOUR-INSTANCE-IP>
```

### Step 3: Run Fix Script

```bash
# Download and run the fix script
curl -sSL https://raw.githubusercontent.com/YogeshAbnave/ollama-terraform/main/fix-deployment.sh | sudo bash
```

**OR** if that doesn't work:

```bash
# Manual fix
cd /home/ubuntu/deployment
sudo bash fix-deployment.sh
```

### Step 4: Access WebUI

```
http://<YOUR-INSTANCE-IP>:8080
```

---

## Manual Fix (If Script Doesn't Work)

### 1. Install Everything Manually

```bash
# SSH into instance
ssh -i ollama-key.pem ubuntu@<YOUR-IP>

# Install git
sudo apt-get update
sudo apt-get install -y git

# Clone repository
cd /home/ubuntu
git clone https://github.com/YogeshAbnave/ollama-terraform.git deployment
cd deployment

# Install Ollama
sudo snap install ollama
sleep 5

# Install Docker
sudo snap install docker
sleep 10

# Download model
echo "exit" | ollama run deepseek-r1:8b

# Remove old container
sudo docker rm -f open-webui 2>/dev/null || true

# Start Open-WebUI
sudo docker run -d \
  --network host \
  --name open-webui \
  -p 8080:8080 \
  -e OLLAMA_BASE_URL=http://127.0.0.1:11434 \
  -v open-webui:/app/backend/data \
  --add-host=host.docker.internal:host-gateway \
  --restart always \
  ghcr.io/open-webui/open-webui:main

# Wait and verify
sleep 10
sudo docker ps | grep open-webui
```

### 2. Verify Everything is Running

```bash
# Check Ollama
sudo ss -tnlp | grep 11434

# Check Docker
sudo docker ps

# Check port 8080
sudo ss -tnlp | grep 8080

# Test Ollama API
curl http://localhost:11434/api/tags

# Test WebUI
curl http://localhost:8080
```

### 3. Check Logs if Still Not Working

```bash
# User-data logs
sudo tail -100 /var/log/user-data.log

# Docker logs
sudo docker logs open-webui

# Ollama logs
sudo journalctl -u snap.ollama.ollama.service -n 50
```

---

## Common Issues & Solutions

### Issue 1: Port 8080 Not Accessible

**Check Security Group:**
```bash
# From local machine
aws ec2 describe-security-groups \
  --group-ids $(terraform output -raw security_group_id) \
  --query 'SecurityGroups[0].IpPermissions'
```

**Should show port 8080 open to 0.0.0.0/0**

**Fix in Terraform:**
Already fixed in `terraform-ec2.tf` - redeploy if needed.

### Issue 2: Container Not Starting

**Check Docker logs:**
```bash
sudo docker logs open-webui
```

**Common fixes:**
```bash
# Restart Docker
sudo snap restart docker
sleep 5

# Recreate container
sudo docker rm -f open-webui
sudo docker run -d \
  --network host \
  --name open-webui \
  -p 8080:8080 \
  -e OLLAMA_BASE_URL=http://127.0.0.1:11434 \
  -v open-webui:/app/backend/data \
  --restart always \
  ghcr.io/open-webui/open-webui:main
```

### Issue 3: Ollama Not Running

**Check status:**
```bash
sudo snap services ollama
```

**Fix:**
```bash
# Restart Ollama
sudo snap restart ollama
sleep 5

# Or reinstall
sudo snap remove ollama
sudo snap install ollama
```

### Issue 4: Model Not Downloaded

**Check models:**
```bash
ollama list
```

**Download manually:**
```bash
# For deepseek-r1:8b
echo "exit" | ollama run deepseek-r1:8b

# Wait 5-10 minutes for download
```

---

## Nuclear Option: Complete Redeploy

If nothing works, destroy and recreate:

```bash
# From local machine
terraform destroy -auto-approve
sleep 120  # Wait 2 minutes
terraform apply -auto-approve
```

Then wait 15 minutes and try accessing WebUI.

---

## Verification Checklist

After fix, verify:

- [ ] Can SSH into instance
- [ ] Git is installed: `git --version`
- [ ] Repository cloned: `ls /home/ubuntu/deployment`
- [ ] Ollama installed: `ollama --version`
- [ ] Ollama running: `sudo ss -tnlp | grep 11434`
- [ ] Docker installed: `docker --version`
- [ ] Container running: `sudo docker ps | grep open-webui`
- [ ] Port 8080 listening: `sudo ss -tnlp | grep 8080`
- [ ] WebUI accessible: `curl http://localhost:8080`
- [ ] Can access from browser: `http://<ip>:8080`

---

## Get Help

If still not working:

1. **Collect logs:**
   ```bash
   sudo tar -czf logs.tar.gz \
     /var/log/user-data.log \
     /var/log/cloud-init*.log \
     /home/ubuntu/deployment-status.txt
   ```

2. **Download logs:**
   ```bash
   scp -i ollama-key.pem ubuntu@<ip>:logs.tar.gz .
   ```

3. **Check these:**
   - User-data log for errors
   - Docker container logs
   - Security group settings
   - Instance has public IP
   - Waited full 15 minutes

---

## Success Indicators

You know it's working when:

✅ `sudo docker ps` shows open-webui running  
✅ `sudo ss -tnlp | grep 8080` shows port listening  
✅ `curl http://localhost:8080` returns HTML  
✅ Browser shows Open-WebUI login page  
✅ Can register user and chat  

---

## Quick Commands Reference

```bash
# SSH in
ssh -i ollama-key.pem ubuntu@<ip>

# Check everything
sudo docker ps
sudo ss -tnlp | grep -E "8080|11434"
ollama list

# Restart everything
sudo snap restart ollama
sudo docker restart open-webui

# View logs
sudo tail -f /var/log/user-data.log
sudo docker logs -f open-webui

# Get WebUI URL
curl -s ifconfig.me
# Then: http://<that-ip>:8080
```

---

**The fix script should resolve most issues automatically!**

Run: `curl -sSL https://raw.githubusercontent.com/YogeshAbnave/ollama-terraform/main/fix-deployment.sh | sudo bash`
