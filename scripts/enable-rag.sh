#!/bin/bash
################################################################################
# RAG Implementation Script for Ollama + Open-WebUI
# This script enables RAG (Retrieval-Augmented Generation) features
# Run this on your EC2 instance to add document upload and semantic search
################################################################################

set -e

echo "=========================================="
echo "🚀 RAG Implementation for Open-WebUI"
echo "=========================================="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "⚠️  This script needs sudo privileges"
    echo "Re-running with sudo..."
    exec sudo bash "$0" "$@"
fi

# Configuration
RAG_ENABLED="${RAG_ENABLED:-true}"
RAG_EMBEDDING_MODEL="${RAG_EMBEDDING_MODEL:-sentence-transformers/all-MiniLM-L6-v2}"
RAG_TOP_K="${RAG_TOP_K:-5}"
CHUNK_SIZE="${CHUNK_SIZE:-512}"
CHUNK_OVERLAP="${CHUNK_OVERLAP:-50}"
SIMILARITY_THRESHOLD="${SIMILARITY_THRESHOLD:-0.7}"

echo "Configuration:"
echo "  RAG Enabled: $RAG_ENABLED"
echo "  Embedding Model: $RAG_EMBEDDING_MODEL"
echo "  Top-K Results: $RAG_TOP_K"
echo "  Chunk Size: $CHUNK_SIZE tokens"
echo "  Chunk Overlap: $CHUNK_OVERLAP tokens"
echo "  Similarity Threshold: $SIMILARITY_THRESHOLD"
echo ""

################################################################################
# Step 1: Check Prerequisites
################################################################################

echo "Step 1: Checking prerequisites..."
echo "-----------------------------------"

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker not found. Please install Docker first."
    exit 1
fi
echo "✅ Docker is installed"

# Check if Ollama is running
if ! ss -tnlp | grep -q 11434; then
    echo "⚠️  Ollama not running on port 11434"
    echo "   Starting Ollama..."
    snap start ollama 2>/dev/null || systemctl start snap.ollama.ollama.service 2>/dev/null || true
    sleep 5
fi

if ss -tnlp | grep -q 11434; then
    echo "✅ Ollama is running"
else
    echo "❌ Ollama failed to start. Please check Ollama installation."
    exit 1
fi

echo ""

################################################################################
# Step 2: Stop Existing Open-WebUI Container
################################################################################

echo "Step 2: Stopping existing Open-WebUI container..."
echo "-----------------------------------"

if docker ps -a --filter name=open-webui --format '{{.Names}}' | grep -q open-webui; then
    echo "Stopping and removing existing container..."
    docker stop open-webui 2>/dev/null || true
    docker rm open-webui 2>/dev/null || true
    echo "✅ Existing container removed"
else
    echo "✅ No existing container found"
fi

echo ""

################################################################################
# Step 3: Create Docker Volumes
################################################################################

echo "Step 3: Creating Docker volumes..."
echo "-----------------------------------"

# Create volume for Open-WebUI data
if ! docker volume inspect open-webui &>/dev/null; then
    docker volume create open-webui
    echo "✅ Created open-webui volume"
else
    echo "✅ open-webui volume already exists"
fi

# Create volume for ChromaDB data
if ! docker volume inspect chroma-data &>/dev/null; then
    docker volume create chroma-data
    echo "✅ Created chroma-data volume"
else
    echo "✅ chroma-data volume already exists"
fi

echo ""

################################################################################
# Step 4: Deploy Open-WebUI with RAG Configuration
################################################################################

echo "Step 4: Deploying Open-WebUI with RAG..."
echo "-----------------------------------"

echo "Starting Open-WebUI container with RAG enabled..."

docker run -d \
  --network host \
  --name open-webui \
  -p 8080:8080 \
  -e OLLAMA_BASE_URL=http://127.0.0.1:11434 \
  -e ENABLE_RAG_WEB_SEARCH=false \
  -e ENABLE_RAG_LOCAL_WEB_FETCH=true \
  -e RAG_EMBEDDING_MODEL="$RAG_EMBEDDING_MODEL" \
  -e RAG_TOP_K="$RAG_TOP_K" \
  -e CHUNK_SIZE="$CHUNK_SIZE" \
  -e CHUNK_OVERLAP="$CHUNK_OVERLAP" \
  -e RAG_TEMPLATE="Use the following context as your learned knowledge:\n\n{context}\n\nUser Query: {query}\n\nPlease answer the query based on the context above. If the context doesn't contain relevant information, say so." \
  -v open-webui:/app/backend/data \
  -v chroma-data:/app/backend/data/vector_db \
  --add-host=host.docker.internal:host-gateway \
  --restart always \
  ghcr.io/open-webui/open-webui:main

echo "✅ Open-WebUI container started"
echo ""

################################################################################
# Step 5: Wait for Container to Start
################################################################################

echo "Step 5: Waiting for Open-WebUI to start..."
echo "-----------------------------------"

echo "Waiting for container to be healthy (this may take 30-60 seconds)..."
sleep 10

# Wait up to 60 seconds for the container to be running
COUNTER=0
MAX_WAIT=60
while [ $COUNTER -lt $MAX_WAIT ]; do
    if docker ps | grep -q open-webui; then
        echo "✅ Container is running"
        break
    fi
    sleep 2
    COUNTER=$((COUNTER + 2))
    echo -n "."
done

if [ $COUNTER -ge $MAX_WAIT ]; then
    echo ""
    echo "⚠️  Container took longer than expected to start"
    echo "   Checking container logs..."
    docker logs open-webui --tail 20
fi

echo ""

################################################################################
# Step 6: Download Embedding Model
################################################################################

echo "Step 6: Pre-downloading embedding model..."
echo "-----------------------------------"

echo "The embedding model will be downloaded automatically on first use."
echo "This may take a few minutes depending on your connection."
echo ""
echo "Model: $RAG_EMBEDDING_MODEL"
echo "Size: ~80MB"
echo ""
echo "✅ Model will download when you upload your first document"

echo ""

################################################################################
# Step 7: Verify Installation
################################################################################

echo "Step 7: Verifying installation..."
echo "-----------------------------------"

# Check if container is running
if docker ps | grep -q open-webui; then
    echo "✅ Open-WebUI container is running"
else
    echo "❌ Open-WebUI container is NOT running"
    echo "Container logs:"
    docker logs open-webui --tail 30
    exit 1
fi

# Check if port 8080 is listening
sleep 5
if ss -tnlp | grep -q 8080; then
    echo "✅ Port 8080 is listening"
else
    echo "⚠️  Port 8080 is not listening yet (may still be starting)"
fi

# Test HTTP endpoint
echo "Testing HTTP endpoint..."
if curl -s -o /dev/null -w "%{http_code}" http://localhost:8080 | grep -q "200\|302"; then
    echo "✅ Open-WebUI is responding"
else
    echo "⚠️  Open-WebUI not responding yet (may still be initializing)"
fi

# Check volumes
echo "Checking volumes..."
if docker volume inspect open-webui &>/dev/null && docker volume inspect chroma-data &>/dev/null; then
    echo "✅ Docker volumes created successfully"
else
    echo "⚠️  Volume creation issue detected"
fi

echo ""

################################################################################
# Step 8: Display Configuration
################################################################################

echo "Step 8: RAG Configuration Summary"
echo "-----------------------------------"

# Get public IP
PUBLIC_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s icanhazip.com 2>/dev/null || echo "unknown")

cat << EOF

========================================
🎉 RAG Implementation Complete!
========================================

Your Open-WebUI now has RAG capabilities enabled!

📍 Access Information:
   WebUI URL: http://$PUBLIC_IP:8080
   Local URL: http://localhost:8080

🔧 RAG Configuration:
   Embedding Model: $RAG_EMBEDDING_MODEL
   Top-K Results: $RAG_TOP_K
   Chunk Size: $CHUNK_SIZE tokens
   Chunk Overlap: $CHUNK_OVERLAP tokens
   Similarity Threshold: $SIMILARITY_THRESHOLD

📚 How to Use RAG:

1. Access Open-WebUI at http://$PUBLIC_IP:8080
2. Log in (or register if first time)
3. Click on your profile → Settings
4. Go to "Documents" section
5. Upload your documents (PDF, TXT, MD, DOCX)
6. Wait for indexing to complete
7. In chat, enable "Use Documents" toggle
8. Ask questions about your documents!

📁 Supported File Formats:
   ✅ PDF (.pdf)
   ✅ Text (.txt)
   ✅ Markdown (.md)
   ✅ Word (.docx)

💡 Tips:
   - First document upload will download the embedding model (~80MB)
   - Larger documents take longer to index
   - Use specific questions for better results
   - Check "Sources" in responses to see which documents were used

🔍 Monitoring:
   View logs: docker logs -f open-webui
   Check status: docker ps | grep open-webui
   Restart: docker restart open-webui

📊 Storage Locations:
   Open-WebUI data: open-webui volume
   Vector database: chroma-data volume
   
🛠️  Troubleshooting:
   If RAG isn't working:
   1. Check container logs: docker logs open-webui
   2. Verify volumes: docker volume ls
   3. Restart container: docker restart open-webui
   4. Re-run this script: bash $0

📖 Documentation:
   Open-WebUI Docs: https://docs.openwebui.com
   RAG Guide: https://docs.openwebui.com/features/rag

========================================

EOF

################################################################################
# Step 9: Create RAG Status File
################################################################################

cat > /home/ubuntu/rag-status.txt <<EOF
RAG Implementation Status
========================

Installation Date: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
Status: Enabled

Configuration:
- Embedding Model: $RAG_EMBEDDING_MODEL
- Top-K Results: $RAG_TOP_K
- Chunk Size: $CHUNK_SIZE
- Chunk Overlap: $CHUNK_OVERLAP
- Similarity Threshold: $SIMILARITY_THRESHOLD

Container: open-webui
Volumes: open-webui, chroma-data

Access URL: http://$PUBLIC_IP:8080

To check container status:
  docker ps | grep open-webui

To view logs:
  docker logs -f open-webui

To restart:
  docker restart open-webui

To disable RAG:
  docker stop open-webui
  docker rm open-webui
  # Then run the original deployment without RAG variables
EOF

chown ubuntu:ubuntu /home/ubuntu/rag-status.txt
echo "✅ Status file created: /home/ubuntu/rag-status.txt"

echo ""
echo "=========================================="
echo "✨ Setup Complete! Enjoy RAG! ✨"
echo "=========================================="
