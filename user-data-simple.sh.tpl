#!/bin/bash
################################################################################
# EC2 User Data Script for Ollama + Open-WebUI Deployment
# This script runs on first boot to install everything directly
################################################################################

set -e  # Exit on any error
set -u  # Exit on undefined variables
set -o pipefail  # Catch pipe failures

# Configuration from Terraform variables
DEFAULT_MODEL="${default_model}"
LOG_FILE="/var/log/user-data.log"
STATUS_FILE="/home/ubuntu/deployment-status.txt"

# Redirect all output to log file
exec > >(tee -a "$LOG_FILE")
exec 2>&1

echo "=========================================="
echo "Starting Ollama + Open-WebUI Deployment"
echo "=========================================="
echo "Timestamp: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
echo "Default Model: $DEFAULT_MODEL"
echo "=========================================="

# Wait for cloud-init to complete
echo "[INFO] Waiting for cloud-init to complete..."
cloud-init status --wait
echo "[SUCCESS] Cloud-init completed"

# Update system packages
echo "[INFO] Updating system packages..."
apt-get update -y
echo "[SUCCESS] System packages updated"

# Install Ollama
echo "[INFO] Installing Ollama..."
if command -v ollama &> /dev/null; then
    echo "[INFO] Ollama already installed, skipping..."
else
    snap install ollama
    sleep 5
    echo "[SUCCESS] Ollama installed successfully"
fi

# Verify Ollama installation
echo "[INFO] Verifying Ollama installation..."
ollama --version
echo "[SUCCESS] Ollama is functional"

# Install Docker
echo "[INFO] Installing Docker..."
if command -v docker &> /dev/null; then
    echo "[INFO] Docker already installed, skipping..."
else
    snap install docker
    sleep 5
    echo "[SUCCESS] Docker installed successfully"
fi

# Verify Docker installation
echo "[INFO] Verifying Docker installation..."
docker --version
echo "[SUCCESS] Docker is functional"

# Wait for services to initialize
echo "[INFO] Waiting for services to initialize..."
sleep 10

# Map model choice to model name
case "$DEFAULT_MODEL" in
    1) MODEL_NAME="deepseek-r1:8b" ;;
    2) MODEL_NAME="deepseek-r1:14b" ;;
    3) MODEL_NAME="deepseek-r1:32b" ;;
    4) MODEL_NAME="llama3.2:3b" ;;
    5) MODEL_NAME="llama3.2:8b" ;;
    6) MODEL_NAME="qwen2.5:7b" ;;
    *) MODEL_NAME="deepseek-r1:8b" ;;
esac

# Download and install model
echo "[INFO] Downloading model: $MODEL_NAME"
echo "[WARNING] This may take several minutes depending on model size..."

# Check if model is already installed
if ollama list 2>/dev/null | grep -q "$MODEL_NAME"; then
    echo "[INFO] Model $MODEL_NAME already installed, skipping..."
else
    # Run model to download it (send exit command to quit after download)
    echo "exit" | ollama run "$MODEL_NAME" || true
    sleep 5
    echo "[SUCCESS] Model $MODEL_NAME installed successfully"
fi

# Remove existing Open-WebUI container if it exists
echo "[INFO] Checking for existing Open-WebUI container..."
if docker ps -a --filter name=open-webui --format '{{.Names}}' | grep -q open-webui; then
    echo "[INFO] Removing existing Open-WebUI container..."
    docker rm -f open-webui
    echo "[SUCCESS] Existing container removed"
fi

# Deploy Open-WebUI container
echo "[INFO] Deploying Open-WebUI container..."
docker run -d \
  --network host \
  --name open-webui \
  -p 3000:8080 \
  -e OLLAMA_BASE_URL=http://localhost:11434 \
  -v open-webui:/app/backend/data \
  --add-host=host.docker.internal:host-gateway \
  --restart always \
  ghcr.io/open-webui/open-webui:main

echo "[SUCCESS] Open-WebUI container deployed"

# Wait for container to start
echo "[INFO] Waiting for Open-WebUI to start..."
sleep 15

# Get machine IP address
MACHINE_IP=$(curl -s ifconfig.me || echo "unknown")
WEBUI_URL="http://$MACHINE_IP:8080"

# Verify Ollama is running
echo "[INFO] Verifying Ollama service..."
if ss -tnlp | grep -q ollama; then
    echo "[SUCCESS] Ollama is running on port 11434"
else
    echo "[WARNING] Ollama might not be running properly"
fi

# Test Ollama API
echo "[INFO] Testing Ollama API..."
if curl -s http://localhost:11434/api/tags > /dev/null; then
    echo "[SUCCESS] Ollama API is responding"
else
    echo "[WARNING] Ollama API is not responding"
fi

# Verify Open-WebUI container
echo "[INFO] Verifying Open-WebUI container..."
if docker ps | grep -q open-webui; then
    echo "[SUCCESS] Open-WebUI container is running"
else
    echo "[ERROR] Open-WebUI container is not running"
fi

# Create deployment status file
cat > "$STATUS_FILE" <<EOF
{
  "status": "success",
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "components": {
    "ollama_install": "success",
    "docker_install": "success",
    "model_download": "success",
    "webui_deploy": "success"
  },
  "webui_url": "$WEBUI_URL",
  "model": "$MODEL_NAME",
  "log_file": "$LOG_FILE"
}
EOF

chown ubuntu:ubuntu "$STATUS_FILE"

# Setup MOTD
cat > /etc/update-motd.d/99-ollama-deployment <<'MOTD_EOF'
#!/bin/bash
echo ""
echo "=========================================="
echo "  Ollama + Open-WebUI Deployment Info"
echo "=========================================="
echo ""
echo "Deployment Log: /var/log/user-data.log"
echo "Status File: /home/ubuntu/deployment-status.txt"
echo ""
if [ -f /home/ubuntu/deployment-status.txt ]; then
    echo "Deployment Status:"
    cat /home/ubuntu/deployment-status.txt | grep -E '"status"|"webui_url"|"model"' | sed 's/^/  /'
    echo ""
fi
echo "View logs: sudo tail -f /var/log/user-data.log"
echo "Check status: cat /home/ubuntu/deployment-status.txt"
echo ""
MOTD_EOF

chmod +x /etc/update-motd.d/99-ollama-deployment

echo ""
echo "=========================================="
echo "Deployment Complete!"
echo "=========================================="
echo "WebUI URL: $WEBUI_URL"
echo "Model: $MODEL_NAME"
echo "Access the interface at: $WEBUI_URL"
echo "First user to register becomes admin"
echo "=========================================="
echo ""
echo "Deployment completed at: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
