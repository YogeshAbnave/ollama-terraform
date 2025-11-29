# How to Upload PDFs to RAG System

## 🎯 Quick Answer

**Upload PDFs through the Open-WebUI web interface at `http://<your-ip>:8080`**

---

## 📋 Step-by-Step Guide

### Step 1: Access Open-WebUI

```
http://<your-ec2-ip>:8080
```

Replace `<your-ec2-ip>` with your actual EC2 instance IP address.

### Step 2: Login or Register

- If first time: Click **"Sign up"** and create an account
- First user automatically becomes admin
- Login with your credentials

### Step 3: Navigate to Documents

```
Profile Icon (top right) → Settings → Documents
```

Or directly:
```
http://<your-ec2-ip>:8080/#/workspace/documents
```

### Step 4: Upload Your PDF

1. Click the **"Upload Document"** button or **"+"** icon
2. Select your PDF file from your computer
3. Wait for upload (progress bar shows)
4. Wait for indexing (status shows "Processing...")
5. When status shows **"Indexed"** - it's ready!

### Step 5: Use in Chat

1. Go back to chat interface (home icon)
2. Start a new conversation
3. Look for **"Use Documents"** toggle (usually at bottom of chat)
4. Enable the toggle
5. Ask questions about your PDF!

---

## 💡 Example Questions to Ask

After uploading a PDF:

- "What is this document about?"
- "Summarize the main points"
- "What does it say about [specific topic]?"
- "Find information about [keyword]"
- "What are the key takeaways?"

The AI will reference your PDF and show sources!

---

## 📂 Where PDFs Are Stored

After upload, PDFs are stored in:

```
Docker Volume: open-webui
Path: /app/backend/data/uploads/

Vector Database: chroma-data
Path: /app/backend/data/vector_db/
```

**Note:** You don't need to access these directly. Everything is managed through the web interface.

---

## 🔄 Alternative Upload Methods

### Method A: Copy PDF to EC2 First

If you have PDFs on your local machine:

```bash
# 1. Copy PDF to EC2
scp -i ollama-key.pem your-document.pdf ubuntu@<your-ip>:/home/ubuntu/

# 2. SSH into EC2
ssh -i ollama-key.pem ubuntu@<your-ip>

# 3. PDF is now at /home/ubuntu/your-document.pdf
# 4. Upload through WebUI as described above
```

### Method B: Using Python Script

```bash
# 1. Copy PDF to EC2
scp -i ollama-key.pem document.pdf ubuntu@<your-ip>:/home/ubuntu/

# 2. SSH into EC2
ssh -i ollama-key.pem ubuntu@<your-ip>

# 3. Use upload script
python3 scripts/upload-document.py document.pdf http://localhost:8080
```

### Method C: Using curl

```bash
# From EC2 instance
curl -X POST http://localhost:8080/api/v1/documents/upload \
  -F "file=@/path/to/your/document.pdf" \
  -H "Authorization: Bearer YOUR_API_KEY"
```

---

## 📊 Supported File Types

| Format | Extension | Max Size | Notes |
|--------|-----------|----------|-------|
| PDF | `.pdf` | 10MB | Text extraction |
| Text | `.txt` | 10MB | Direct processing |
| Markdown | `.md` | 10MB | Preserves formatting |
| Word | `.docx` | 10MB | Text + basic formatting |

---

## ⏱️ Upload & Indexing Time

| Document Size | Upload Time | Indexing Time |
|---------------|-------------|---------------|
| 1-10 pages | < 5 seconds | 5-15 seconds |
| 10-50 pages | 5-15 seconds | 15-60 seconds |
| 50-100 pages | 15-30 seconds | 1-3 minutes |
| 100+ pages | 30-60 seconds | 3-10 minutes |

**Note:** First upload downloads embedding model (~80MB), adding 1-2 minutes.

---

## 🔍 Verifying Upload Success

### Check in WebUI

1. Go to Settings → Documents
2. Your PDF should appear in the list
3. Status should show **"Indexed"**
4. Click on it to see details (chunk count, size, etc.)

### Check via Command Line

```bash
# SSH into EC2
ssh -i ollama-key.pem ubuntu@<your-ip>

# Check uploaded files
docker exec open-webui ls -lh /app/backend/data/uploads/

# Check vector database
docker exec open-webui ls -lh /app/backend/data/vector_db/
```

---

## 🎨 Visual Flow

```
Your Computer                EC2 Instance
    |                            |
    | 1. Open Browser            |
    |--------------------------->|
    |    http://ip:8080          |
    |                            |
    | 2. Login/Register          |
    |<---------------------------|
    |                            |
    | 3. Go to Documents         |
    |--------------------------->|
    |                            |
    | 4. Click Upload            |
    |--------------------------->|
    |                            |
    | 5. Select PDF              |
    |--------------------------->|
    |    [PDF File]              |
    |                            |
    |                            | 6. Process PDF
    |                            | 7. Extract Text
    |                            | 8. Create Chunks
    |                            | 9. Generate Embeddings
    |                            | 10. Store in ChromaDB
    |                            |
    | 11. Show "Indexed"         |
    |<---------------------------|
    |                            |
    | 12. Enable "Use Docs"      |
    |--------------------------->|
    |                            |
    | 13. Ask Question           |
    |--------------------------->|
    |                            |
    |                            | 14. Search Vector DB
    |                            | 15. Retrieve Chunks
    |                            | 16. Send to Ollama
    |                            | 17. Generate Response
    |                            |
    | 18. Get Answer + Sources   |
    |<---------------------------|
```

---

## 🐛 Troubleshooting

### PDF Won't Upload

**Check file size:**
```bash
ls -lh your-document.pdf
# Should be < 10MB
```

**Check file format:**
```bash
file your-document.pdf
# Should show: PDF document
```

**Check WebUI logs:**
```bash
docker logs -f open-webui
```

### Upload Stuck at "Processing"

**Wait longer** - Large PDFs take time

**Check container resources:**
```bash
docker stats open-webui
```

**Restart container:**
```bash
docker restart open-webui
```

### Can't Find Uploaded Document

**Refresh the page** - Browser cache issue

**Check Documents tab:**
```
Settings → Documents → Should see your file
```

**Check storage:**
```bash
docker exec open-webui ls /app/backend/data/uploads/
```

---

## 💾 Managing Your PDFs

### View All Documents

```
Settings → Documents → See full list
```

### Delete a Document

```
Settings → Documents → Click trash icon next to document
```

### Re-upload Updated Version

```
1. Delete old version
2. Upload new version
3. Wait for re-indexing
```

### Check Document Details

```
Settings → Documents → Click on document name
Shows: Size, chunks, upload date, status
```

---

## 🚀 Pro Tips

1. **Organize by topic** - Upload related documents together
2. **Use descriptive filenames** - Easier to find later
3. **Test with small PDFs first** - Verify everything works
4. **Enable "Use Documents" per chat** - Control when RAG is active
5. **Check sources** - Verify AI is using your documents
6. **Re-upload if updated** - Keep documents current

---

## 📞 Need Help?

- **Check logs:** `docker logs open-webui`
- **Test RAG:** `bash scripts/test-rag.sh`
- **Restart:** `docker restart open-webui`
- **Re-setup:** `sudo bash scripts/enable-rag.sh`

---

## 🎯 Quick Reference

```bash
# Access WebUI
http://<your-ip>:8080

# Upload location in WebUI
Profile → Settings → Documents → Upload

# Enable in chat
Toggle "Use Documents" switch

# Check status
Settings → Documents → View list

# Test upload
bash scripts/test-rag.sh
```

---

**That's it! Upload through the web interface and start asking questions!** 🎉
