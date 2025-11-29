#!/bin/bash
################################################################################
# Emergency Fix Script - Run this on EC2 instance to fix deployment
# Usage: ssh into EC2 and run: bash fix-deployment.sh
################################################################################

set -e

echo "=========================================="
echo "🔧 EMERGENCY DEPLOYMENT FIX"
echo "=========================================="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "⚠️  This script needs sudo privileges"
    echo "Re-running with sudo..."
    exec sudo bash "$0" "$@"
fi

echo "Step 1: Checking system status..."
echo "-----------------------------------"

# Check if git is installed
if ! command -v git &> /dev/null; then
    echo "❌ Git not installed. Installing..."
    apt-get update -y
    apt-get install -y git
    echo "✅ Git installed"
else
    echo "✅ Git is installed"
fi

echo ""
echo "Step 2: Checking repository..."
echo "-----------------------------------"

# Check if repository is cloned
if [ ! -d /home/ubuntu/deployment ]; then
    echo "❌ Repository not cloned. Cloning now..."
    cd /home/ubuntu
    git clone https://github.com/YogeshAbnave/ollama-terraform.git deployment
    chown -R ubuntu:ubuntu deployment
    echo "✅ Repository cloned"
else
    echo "✅ Repository exists"
    echo "   Updating repository..."
    cd /home/ubuntu/deployment
    sudo -u ubuntu git pull origin main || echo "⚠️  Could not update (might be okay)"
fi

echo ""
echo "Step 3: Checking Ollama..."
echo "-----------------------------------"

if ! command -v ollama &> /dev/null; then
    echo "❌ Ollama not installed. Installing..."
    snap install ollama
    sleep 5
    echo "✅ Ollama installed"
else
    echo "✅ Ollama is installed"
fi

# Check if Ollama is running
if ! ss -tnlp | grep -q 11434; then
    echo "⚠️  Ollama not running. Starting..."
    snap start ollama || systemctl start snap.ollama.ollama.service
    sleep 5
    echo "✅ Ollama started"
else
    echo "✅ Ollama is running"
fi

echo ""
echo "Step 4: Checking Docker..."
echo "-----------------------------------"

if ! command -v docker &> /dev/null; then
    echo "❌ Docker not installed. Installing..."
    snap install docker
    sleep 5
    echo "✅ Docker installed"
else
    echo "✅ Docker is installed"
fi

echo ""
echo "Step 5: Checking AI Model..."
echo "-----------------------------------"

# Check if model is installed
if ! ollama list 2>/dev/null | grep -q "deepseek-r1:8b"; then
    echo "❌ Model not installed. Downloading..."
    echo "⏳ This will take 5-10 minutes..."
    echo "exit" | ollama run deepseek-r1:8b || true
    sleep 5
    echo "✅ Model downloaded"
else
    echo "✅ Model is installed"
fi

echo ""
echo "Step 6: Fixing Open-WebUI Container..."
echo "-----------------------------------"

# Stop and remove existing container
if docker ps -a | grep -q open-webui; then
    echo "Removing old container..."
    docker rm -f open-webui 2>/dev/null || true
fi

# Create new container with correct configuration
echo "Creating Open-WebUI container..."
docker run -d \
  --network host \
  --name open-webui \
  -p 8080:8080 \
  -e OLLAMA_BASE_URL=http://127.0.0.1:11434 \
  -v open-webui:/app/backend/data \
  --add-host=host.docker.internal:host-gateway \
  --restart always \
  ghcr.io/open-webui/open-webui:main

echo "✅ Container created"

echo ""
echo "Step 7: Waiting for services to start..."
echo "-----------------------------------"
sleep 10

echo ""
echo "Step 8: Verification..."
echo "-----------------------------------"

# Check Ollama
if ss -tnlp | grep -q 11434; then
    echo "✅ Ollama is running on port 11434"
else
    echo "❌ Ollama is NOT running!"
fi

# Check Docker container
if docker ps | grep -q open-webui; then
    echo "✅ Open-WebUI container is running"
    docker ps | grep open-webui
else
    echo "❌ Open-WebUI container is NOT running!"
    echo "Container logs:"
    docker logs open-webui 2>&1 | tail -20
fi

# Check port 8080
if ss -tnlp | grep -q 8080; then
    echo "✅ Port 8080 is listening"
else
    echo "❌ Port 8080 is NOT listening!"
fi

# Test Ollama API
echo ""
echo "Testing Ollama API..."
if curl -s http://localhost:11434/api/tags > /dev/null; then
    echo "✅ Ollama API is responding"
else
    echo "❌ Ollama API is not responding"
fi

# Test WebUI
echo ""
echo "Testing WebUI..."
if curl -s http://localhost:8080 > /dev/null; then
    echo "✅ WebUI is responding"
else
    echo "❌ WebUI is not responding"
fi

echo ""
echo "=========================================="
echo "🎉 FIX COMPLETE!"
echo "=========================================="
echo ""

# Get public IP
PUBLIC_IP=$(curl -s ifconfig.me || curl -s icanhazip.com || echo "unknown")

echo "Your WebUI URL: http://$PUBLIC_IP:8080"
echo ""
echo "If WebUI still doesn't work:"
echo "1. Wait 2-3 minutes for container to fully start"
echo "2. Check container logs: docker logs open-webui"
echo "3. Restart container: docker restart open-webui"
echo "4. Check security group allows port 8080"
echo ""
echo "=========================================="
