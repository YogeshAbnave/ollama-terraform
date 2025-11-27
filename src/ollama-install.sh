#!/bin/bash

# Ollama and Open-WebUI Installation Script
# This script installs Ollama, Docker, and sets up Open-WebUI

set -e  # Exit on any error

echo "🚀 Starting Ollama and Open-WebUI setup..."

# Update system packages
echo "📦 Updating system packages..."
sudo apt update

# Install Ollama
echo "🤖 Installing Ollama..."
sudo snap install ollama

# Check Ollama version
echo "✅ Checking Ollama installation..."
ollama --version

# Install Docker
echo "🐳 Installing Docker..."
sudo snap install docker

# Wait for services to start
echo "⏳ Waiting for services to initialize..."
sleep 5

# Ask user for model selection
echo ""
echo "🧠 Choose an Ollama model to install:"
echo "1) deepseek-r1:8b (Recommended - 8B parameters)"
echo "2) deepseek-r1:14b (Larger model - 14B parameters)"
echo "3) deepseek-r1:32b (Large model - 32B parameters)"
echo "4) llama3.2:3b (Lightweight - 3B parameters)"
echo "5) llama3.2:8b (Balanced - 8B parameters)"
echo "6) qwen2.5:7b (Alternative - 7B parameters)"
echo "7) Custom model (enter manually)"
echo "8) Skip model installation"
echo ""

while true; do
    read -p "Enter your choice (1-8): " model_choice
    
    case $model_choice in
        1)
            MODEL_NAME="deepseek-r1:8b"
            break
            ;;
        2)
            MODEL_NAME="deepseek-r1:14b"
            break
            ;;
        3)
            MODEL_NAME="deepseek-r1:32b"
            break
            ;;
        4)
            MODEL_NAME="llama3.2:3b"
            break
            ;;
        5)
            MODEL_NAME="llama3.2:8b"
            break
            ;;
        6)
            MODEL_NAME="qwen2.5:7b"
            break
            ;;
        7)
            read -p "Enter custom model name (e.g., llama3:7b): " MODEL_NAME
            if [[ -n "$MODEL_NAME" ]]; then
                break
            else
                echo "❌ Model name cannot be empty. Please try again."
            fi
            ;;
        8)
            MODEL_NAME=""
            break
            ;;
        *)
            echo "❌ Invalid choice. Please enter 1-8."
            ;;
    esac
done

if [[ -n "$MODEL_NAME" ]]; then
    echo "🚀 Downloading and running model: $MODEL_NAME"
    echo "⚠️  This may take several minutes depending on model size..."
    ollama run "$MODEL_NAME"
    echo "✅ Model $MODEL_NAME installed successfully"
else
    echo "⏭️  Skipping model installation"
fi

# Run Open-WebUI Docker container
echo "🌐 Setting up Open-WebUI..."
sudo docker run -d \
  --network host \
  --name open-webui \
  -p 3000:8080 \
  -e OLLAMA_BASE_URL=http://localhost:11434 \
  -v open-webui:/app/backend/data \
  --add-host=host.docker.internal:host-gateway \
  --restart always \
  ghcr.io/open-webui/open-webui:main

# Wait for container to start
echo "⏳ Waiting for Open-WebUI to start..."
sleep 10

# Get machine IP address
MACHINE_IP=$(curl ifconfig.me | awk '{print $1}')

# Verify Ollama is running
echo "🔍 Verifying Ollama service..."
if sudo ss -tnlp | grep -q ollama; then
    echo "✅ Ollama is running on port 11434"
else
    echo "⚠️  Warning: Ollama might not be running properly"
fi

# Test Ollama API
echo "🧪 Testing Ollama API..."
if curl -s http://localhost:11434/api/tags > /dev/null; then
    echo "✅ Ollama API is responding"
else
    echo "⚠️  Warning: Ollama API is not responding"
fi

echo ""
echo "🎉 Installation complete!"
echo "📍 Access Open-WebUI at: http://$MACHINE_IP:8080/"
echo "📍 Or use: http://localhost:8080/"
echo ""
echo "💡 If you encounter issues, check the troubleshooting section in cleanup.sh"