# RAG Quick Reference

## One-Line Setup

```bash
ssh -i ollama-key.pem ubuntu@<your-ip> 'curl -sSL https://raw.githubusercontent.com/YogeshAbnave/ollama-terraform/main/scripts/enable-rag.sh | sudo bash'
```

---

## Essential Commands

### Setup & Management

```bash
# Enable RAG
sudo bash scripts/enable-rag.sh

# Test RAG
bash scripts/test-rag.sh

# Check status
cat /home/ubuntu/rag-status.txt

# View logs
docker logs -f open-webui

# Restart
docker restart open-webui
```

### Configuration

```bash
# Custom top-k
export RAG_TOP_K=10
sudo -E bash scripts/enable-rag.sh

# Custom chunk size
export CHUNK_SIZE=1024
export CHUNK_OVERLAP=200
sudo -E bash scripts/enable-rag.sh

# Different embedding model
export RAG_EMBEDDING_MODEL="sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2"
sudo -E bash scripts/enable-rag.sh
```

---

## Quick Troubleshooting

| Problem | Solution |
|---------|----------|
| Container not running | `docker start open-webui` |
| RAG not working | `docker restart open-webui` |
| Documents not indexing | Check logs: `docker logs open-webui` |
| Slow queries | Reduce `RAG_TOP_K` to 3 |
| Out of memory | Reduce `CHUNK_SIZE` to 256 |
| Need to reset | Re-run `enable-rag.sh` |

---

## File Formats

| Format | Extension | Max Size |
|--------|-----------|----------|
| PDF | `.pdf` | 10MB |
| Text | `.txt` | 10MB |
| Markdown | `.md` | 10MB |
| Word | `.docx` | 10MB |

---

## Default Configuration

```bash
RAG_ENABLED=true
RAG_EMBEDDING_MODEL=sentence-transformers/all-MiniLM-L6-v2
RAG_TOP_K=5
CHUNK_SIZE=512
CHUNK_OVERLAP=50
SIMILARITY_THRESHOLD=0.7
```

---

## Usage Flow

1. **Upload** → Settings → Documents → Upload
2. **Wait** → Document indexes (1-5 sec/page)
3. **Enable** → Toggle "Use Documents" in chat
4. **Query** → Ask questions about documents
5. **View** → Check sources in response

---

## Performance Tuning

### Small Documents
```bash
CHUNK_SIZE=256 CHUNK_OVERLAP=25 RAG_TOP_K=3
```

### Large Documents
```bash
CHUNK_SIZE=1024 CHUNK_OVERLAP=200 RAG_TOP_K=10
```

### Technical Docs
```bash
CHUNK_SIZE=512 CHUNK_OVERLAP=100 RAG_TOP_K=7
```

---

## Monitoring

```bash
# Container stats
docker stats open-webui

# Disk usage
docker system df -v

# Memory usage
free -h

# Storage location
docker volume inspect chroma-data
```

---

## Backup & Restore

```bash
# Backup
docker run --rm -v chroma-data:/data -v $(pwd):/backup ubuntu tar czf /backup/rag-backup.tar.gz /data

# Restore
docker run --rm -v chroma-data:/data -v $(pwd):/backup ubuntu tar xzf /backup/rag-backup.tar.gz -C /
```

---

## API Examples

### Upload Document (Python)

```python
import requests

url = "http://your-ip:8080/api/v1/documents/upload"
files = {"file": open("document.pdf", "rb")}
headers = {"Authorization": "Bearer YOUR_TOKEN"}

response = requests.post(url, files=files, headers=headers)
print(response.json())
```

### Query with RAG (Python)

```python
import requests

url = "http://your-ip:8080/api/chat"
data = {
    "model": "deepseek-r1:8b",
    "messages": [{"role": "user", "content": "What is in my documents?"}],
    "use_rag": True
}
headers = {"Authorization": "Bearer YOUR_TOKEN"}

response = requests.post(url, json=data, headers=headers)
print(response.json())
```

---

## Links

- 📖 [Full Setup Guide](RAG-SETUP.md)
- 🏠 [Main README](../README.md)
- 🚀 [Quick Start](QUICKSTART.md)
- 📁 [Project Structure](STRUCTURE.md)

---

**Need Help?** Check logs: `docker logs open-webui`
