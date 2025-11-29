# RAG Setup Guide

## Quick Setup on Existing EC2 Instance

If you already have an Ollama + Open-WebUI deployment running, you can enable RAG features with a single script.

### Option 1: Run Directly from GitHub

```bash
# SSH into your EC2 instance
ssh -i ollama-key.pem ubuntu@<your-instance-ip>

# Download and run the RAG setup script
curl -sSL https://raw.githubusercontent.com/YogeshAbnave/ollama-terraform/main/scripts/enable-rag.sh | sudo bash
```

### Option 2: Run from Local Repository

```bash
# SSH into your EC2 instance
ssh -i ollama-key.pem ubuntu@<your-instance-ip>

# Navigate to deployment directory
cd /home/ubuntu/deployment

# Pull latest changes
git pull origin main

# Run the RAG setup script
sudo bash scripts/enable-rag.sh
```

### Option 3: Custom Configuration

```bash
# SSH into your EC2 instance
ssh -i ollama-key.pem ubuntu@<your-instance-ip>

# Set custom RAG parameters
export RAG_TOP_K=10
export CHUNK_SIZE=1024
export CHUNK_OVERLAP=100

# Run the script with custom config
sudo -E bash scripts/enable-rag.sh
```

---

## What the Script Does

1. ✅ Checks prerequisites (Docker, Ollama)
2. ✅ Stops existing Open-WebUI container
3. ✅ Creates Docker volumes for data persistence
4. ✅ Deploys Open-WebUI with RAG configuration
5. ✅ Configures ChromaDB vector database
6. ✅ Sets up embedding model (sentence-transformers)
7. ✅ Verifies installation
8. ✅ Creates status file with configuration

**Total Time:** ~2-3 minutes

---

## Configuration Options

You can customize RAG behavior by setting environment variables before running the script:

| Variable | Default | Description |
|----------|---------|-------------|
| `RAG_ENABLED` | `true` | Enable/disable RAG features |
| `RAG_EMBEDDING_MODEL` | `sentence-transformers/all-MiniLM-L6-v2` | Embedding model to use |
| `RAG_TOP_K` | `5` | Number of chunks to retrieve |
| `CHUNK_SIZE` | `512` | Size of document chunks (tokens) |
| `CHUNK_OVERLAP` | `50` | Overlap between chunks (tokens) |
| `SIMILARITY_THRESHOLD` | `0.7` | Minimum similarity score |

### Example: High-Precision Configuration

```bash
export RAG_TOP_K=3
export CHUNK_SIZE=256
export SIMILARITY_THRESHOLD=0.85
sudo -E bash scripts/enable-rag.sh
```

### Example: Large Document Configuration

```bash
export RAG_TOP_K=10
export CHUNK_SIZE=1024
export CHUNK_OVERLAP=200
sudo -E bash scripts/enable-rag.sh
```

---

## Using RAG Features

### 1. Upload Documents

1. Access Open-WebUI at `http://<your-ip>:8080`
2. Log in (or register if first time)
3. Click your profile icon → **Settings**
4. Go to **Documents** section
5. Click **Upload Document**
6. Select your file (PDF, TXT, MD, DOCX)
7. Wait for indexing to complete

### 2. Query with RAG

1. Start a new chat
2. Enable the **"Use Documents"** toggle
3. Ask questions about your uploaded documents
4. View sources in the response

### 3. Manage Documents

**View Documents:**
- Settings → Documents → See all uploaded files

**Delete Documents:**
- Settings → Documents → Click trash icon

**Check Status:**
- Documents show "Indexed" when ready

---

## Supported File Formats

| Format | Extension | Notes |
|--------|-----------|-------|
| PDF | `.pdf` | Text extraction, preserves structure |
| Text | `.txt` | Direct processing |
| Markdown | `.md` | Preserves formatting |
| Word | `.docx` | Text and basic formatting |

**File Size Limit:** 10MB per document (configurable)

---

## Troubleshooting

### RAG Not Working

**Check container status:**
```bash
docker ps | grep open-webui
```

**View logs:**
```bash
docker logs -f open-webui
```

**Restart container:**
```bash
docker restart open-webui
```

### Documents Not Indexing

**Check embedding model:**
```bash
docker exec open-webui ls -la /app/backend/data/cache/embedding/models
```

**Re-run setup:**
```bash
sudo bash scripts/enable-rag.sh
```

### Slow Queries

**Reduce top-k:**
```bash
export RAG_TOP_K=3
sudo -E bash scripts/enable-rag.sh
```

**Increase chunk size:**
```bash
export CHUNK_SIZE=1024
sudo -E bash scripts/enable-rag.sh
```

### Out of Memory

**Check memory usage:**
```bash
docker stats open-webui
```

**Reduce chunk size:**
```bash
export CHUNK_SIZE=256
export RAG_TOP_K=3
sudo -E bash scripts/enable-rag.sh
```

---

## Monitoring

### Check RAG Status

```bash
cat /home/ubuntu/rag-status.txt
```

### View Container Logs

```bash
# Real-time logs
docker logs -f open-webui

# Last 100 lines
docker logs --tail 100 open-webui
```

### Check Storage Usage

```bash
# Volume sizes
docker system df -v

# Disk usage
df -h
```

### Monitor Performance

```bash
# Container stats
docker stats open-webui

# System resources
htop
```

---

## Disabling RAG

If you want to disable RAG and revert to standard Open-WebUI:

```bash
# Stop and remove container
docker stop open-webui
docker rm open-webui

# Run without RAG variables
docker run -d \
  --network host \
  --name open-webui \
  -p 8080:8080 \
  -e OLLAMA_BASE_URL=http://127.0.0.1:11434 \
  -v open-webui:/app/backend/data \
  --add-host=host.docker.internal:host-gateway \
  --restart always \
  ghcr.io/open-webui/open-webui:main
```

**Note:** Your documents will be preserved in the volumes.

---

## Advanced Configuration

### Custom Embedding Model

```bash
# Use a different model
export RAG_EMBEDDING_MODEL="sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2"
sudo -E bash scripts/enable-rag.sh
```

### External Vector Database

For production deployments, consider using an external vector database:

```bash
# Example with Qdrant
docker run -d \
  --name qdrant \
  -p 6333:6333 \
  -v qdrant-data:/qdrant/storage \
  qdrant/qdrant

# Configure Open-WebUI to use Qdrant
export VECTOR_DB=qdrant
export QDRANT_URL=http://localhost:6333
sudo -E bash scripts/enable-rag.sh
```

### Backup Documents

```bash
# Backup vector database
docker run --rm \
  -v chroma-data:/data \
  -v $(pwd):/backup \
  ubuntu tar czf /backup/chroma-backup.tar.gz /data

# Restore vector database
docker run --rm \
  -v chroma-data:/data \
  -v $(pwd):/backup \
  ubuntu tar xzf /backup/chroma-backup.tar.gz -C /
```

---

## Performance Tuning

### For Small Documents (<100 pages)

```bash
export CHUNK_SIZE=256
export CHUNK_OVERLAP=25
export RAG_TOP_K=3
```

### For Large Documents (>100 pages)

```bash
export CHUNK_SIZE=1024
export CHUNK_OVERLAP=200
export RAG_TOP_K=10
```

### For Technical Documents

```bash
export CHUNK_SIZE=512
export CHUNK_OVERLAP=100
export RAG_TOP_K=7
export SIMILARITY_THRESHOLD=0.75
```

### For Conversational Documents

```bash
export CHUNK_SIZE=768
export CHUNK_OVERLAP=150
export RAG_TOP_K=5
export SIMILARITY_THRESHOLD=0.65
```

---

## FAQ

**Q: How long does document indexing take?**
A: Typically 1-5 seconds per page, depending on document complexity.

**Q: Can I upload multiple documents?**
A: Yes! Upload as many as you need. They'll all be searchable.

**Q: Does RAG work with all Ollama models?**
A: Yes, RAG works with any Ollama model.

**Q: How much storage do documents use?**
A: Approximately 2-3x the original file size (text + embeddings).

**Q: Can I use RAG with web search?**
A: Yes, set `ENABLE_RAG_WEB_SEARCH=true` for hybrid search.

**Q: Is my data private?**
A: Yes! All processing happens locally on your EC2 instance.

---

## Next Steps

1. ✅ Run the setup script
2. ✅ Upload your first document
3. ✅ Ask questions about it
4. ✅ Explore advanced features
5. ✅ Optimize configuration for your use case

---

## Support

- 📖 [Open-WebUI Documentation](https://docs.openwebui.com)
- 🐛 [Report Issues](https://github.com/YogeshAbnave/ollama-terraform/issues)
- 💬 [Discussions](https://github.com/YogeshAbnave/ollama-terraform/discussions)

---

**Happy RAG-ing! 🚀**
