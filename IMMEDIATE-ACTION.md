# 🚨 IMMEDIATE ACTION - Connection Timeout to 52.54.170.140:8080

## The Problem

`ERR_CONNECTION_TIMED_OUT` means port 8080 is not accessible. This is usually because:
1. ❌ Security group doesn't allow port 8080
2. ❌ Open-WebUI container is not running
3. ❌ Installation is still in progress

---

## SOLUTION 1: Check if Services are Running (Do This First!)

### Step 1: SSH into Instance

```powershell
ssh -i ollama-key.pem ubuntu@52.54.170.140
```

### Step 2: Check What's Running

```bash
# Check if Docker container is running
sudo docker ps | grep open-webui

# Check if port 8080 is listening
sudo ss -tnlp | grep 8080

# Check installation logs
sudo tail -50 /var/log/user-data.log
```

### Step 3: If Nothing is Running, Run Fix Script

```bash
# Download and run fix
curl -sSL https://raw.githubusercontent.com/YogeshAbnave/ollama-terraform/main/fix-deployment.sh | sudo bash

# Or if already cloned
cd /home/ubuntu/deployment
sudo bash fix-deployment.sh
```

---

## SOLUTION 2: Check Security Group

### From Your Local Machine:

```powershell
# Get security group ID
terraform output security_group_id

# Check security group rules
aws ec2 describe-security-groups --group-ids <YOUR-SG-ID> --query 'SecurityGroups[0].IpPermissions[*].[FromPort,ToPort,IpProtocol,IpRanges[0].CidrIp]' --output table
```

**Should show:**
- Port 22 (SSH)
- Port 8080 (WebUI) from 0.0.0.0/0
- Port 11434 (Ollama) from 0.0.0.0/0

### If Port 8080 is Missing:

The security group was created before we added port 8080. You need to redeploy:

```powershell
# Destroy and recreate with correct security group
terraform destroy -auto-approve
Start-Sleep -Seconds 120
terraform apply -auto-approve
```

---

## SOLUTION 3: Manual Container Start

If SSH works but container isn't running:

```bash
# SSH in
ssh -i ollama-key.pem ubuntu@52.54.170.140

# Install Docker if needed
if ! command -v docker &> /dev/null; then
    sudo snap install docker
    sleep 10
fi

# Install Ollama if needed
if ! command -v ollama &> /dev/null; then
    sudo snap install ollama
    sleep 10
fi

# Remove old container
sudo docker rm -f open-webui 2>/dev/null || true

# Start new container
sudo docker run -d \
  --network host \
  --name open-webui \
  -p 8080:8080 \
  -e OLLAMA_BASE_URL=http://127.0.0.1:11434 \
  -v open-webui:/app/backend/data \
  --add-host=host.docker.internal:host-gateway \
  --restart always \
  ghcr.io/open-webui/open-webui:main

# Wait and check
sleep 15
sudo docker ps | grep open-webui
sudo ss -tnlp | grep 8080
```

---

## SOLUTION 4: Complete Redeploy (Nuclear Option)

If nothing else works:

```powershell
# Destroy everything
terraform destroy -auto-approve

# Wait for cleanup
Start-Sleep -Seconds 120

# Redeploy with fixed code
terraform apply -auto-approve

# Wait 15-20 minutes for installation
Start-Sleep -Seconds 900

# Try accessing
Start-Process "http://52.54.170.140:8080"
```

---

## Quick Diagnostic

Run this to diagnose the issue:

```powershell
.\diagnose-connection.ps1
```

This will tell you exactly what's wrong.

---

## Most Likely Causes (In Order)

### 1. Services Not Running Yet (70% chance)
**Solution:** Wait 15-20 minutes or run fix script

### 2. Security Group Missing Port 8080 (20% chance)
**Solution:** Redeploy with `terraform destroy && terraform apply`

### 3. Container Failed to Start (10% chance)
**Solution:** SSH in and manually start container

---

## Verification Steps

After applying any solution:

```bash
# On the instance
sudo docker ps | grep open-webui
# Should show: open-webui container running

sudo ss -tnlp | grep 8080
# Should show: something listening on port 8080

curl http://localhost:8080
# Should return HTML

# From your machine
Test-NetConnection -ComputerName 52.54.170.140 -Port 8080
# Should show: TcpTestSucceeded : True
```

---

## Timeline

If you just deployed:
- **0-5 min:** Infrastructure creating
- **5-10 min:** Git clone, Ollama/Docker installing
- **10-15 min:** Model downloading (~4.9GB)
- **15-20 min:** Container starting
- **20+ min:** ✅ Should be accessible

**If it's been less than 20 minutes, just wait!**

---

## The Fastest Fix

```bash
# 1. SSH in
ssh -i ollama-key.pem ubuntu@52.54.170.140

# 2. Run this one command
curl -sSL https://raw.githubusercontent.com/YogeshAbnave/ollama-terraform/main/fix-deployment.sh | sudo bash

# 3. Wait 2-3 minutes

# 4. Access WebUI
# http://52.54.170.140:8080
```

---

## Still Not Working?

1. **Check logs:**
   ```bash
   ssh -i ollama-key.pem ubuntu@52.54.170.140
   sudo tail -100 /var/log/user-data.log
   ```

2. **Check container logs:**
   ```bash
   sudo docker logs open-webui
   ```

3. **Verify security group in AWS Console:**
   - EC2 → Security Groups
   - Find your security group
   - Check Inbound Rules
   - Should have TCP 8080 from 0.0.0.0/0

4. **Nuclear option:**
   ```powershell
   terraform destroy -auto-approve
   Start-Sleep -Seconds 120
   terraform apply -auto-approve
   ```

---

## Success Indicators

You'll know it's working when:

✅ `Test-NetConnection -ComputerName 52.54.170.140 -Port 8080` succeeds  
✅ Browser shows Open-WebUI login page  
✅ Can register user  
✅ Can chat with AI  

---

**Most likely you just need to wait longer or run the fix script!**

Try: `ssh -i ollama-key.pem ubuntu@52.54.170.140` then run the fix script.
