#!/bin/bash
set -e

echo "🚀 Starting Ollama and Open-WebUI setup..."

# Update system packages
echo "📦 Updating system packages..."
apt-get update
apt-get upgrade -y

# Install Ollama
echo "🤖 Installing Ollama..."
snap install ollama

# Wait for Ollama to initialize
sleep 5

# Check Ollama version
echo "✅ Checking Ollama installation..."
ollama --version

# Install Docker
echo "🐳 Installing Docker..."
snap install docker

# Wait for Docker to initialize
sleep 5

# Pull and run Ollama model
OLLAMA_MODEL="${ollama_model}"
if [ -n "$OLLAMA_MODEL" ]; then
    echo "🚀 Downloading Ollama model: $OLLAMA_MODEL"
    ollama pull "$OLLAMA_MODEL" || echo "⚠️ Model pull failed, will retry on first use"
fi

# Create a simple health check endpoint on port 80 FIRST
echo "🏥 Creating health check endpoint..."
mkdir -p /var/www/html
echo "OK" > /var/www/html/index.html
python3 -m http.server 80 --directory /var/www/html &
HEALTH_PID=$!
echo "✅ Health check endpoint running on port 80"

# Run Open-WebUI Docker container
echo "🌐 Setting up Open-WebUI..."
docker run -d \
  --name open-webui \
  -p 8080:8080 \
  -e OLLAMA_BASE_URL=http://localhost:11434 \
  -e WEBUI_AUTH=false \
  -v open-webui:/app/backend/data \
  --add-host=host.docker.internal:host-gateway \
  --restart always \
  ghcr.io/open-webui/open-webui:main

# Wait for container to start
echo "⏳ Waiting for Open-WebUI to start..."
sleep 30

# Once Open-WebUI is ready, stop the health check server and let Open-WebUI take port 80
echo "🔄 Switching to Open-WebUI on port 80..."
kill $HEALTH_PID 2>/dev/null || true
docker stop open-webui
docker rm open-webui
docker run -d \
  --name open-webui \
  -p 80:8080 \
  -e OLLAMA_BASE_URL=http://localhost:11434 \
  -e WEBUI_AUTH=false \
  -v open-webui:/app/backend/data \
  --add-host=host.docker.internal:host-gateway \
  --restart always \
  ghcr.io/open-webui/open-webui:main

sleep 10

# Verify Ollama is running
echo "🔍 Verifying Ollama service..."
if ss -tnlp | grep -q ollama; then
    echo "✅ Ollama is running on port 11434"
else
    echo "⚠️ Warning: Ollama might not be running properly"
fi

# Test Ollama API
echo "🧪 Testing Ollama API..."
if curl -s http://localhost:11434/api/tags > /dev/null; then
    echo "✅ Ollama API is responding"
else
    echo "⚠️ Warning: Ollama API is not responding"
fi

# Verify Docker container
echo "🔍 Verifying Open-WebUI container..."
if docker ps | grep -q open-webui; then
    echo "✅ Open-WebUI container is running"
else
    echo "⚠️ Warning: Open-WebUI container might not be running"
fi

echo "🎉 Ollama and Open-WebUI setup completed!"
echo "📍 Access Open-WebUI at: http://$(curl -s ifconfig.me)/"
