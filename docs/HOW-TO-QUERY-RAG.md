# How to Retrieve Data from RAG by Asking Questions

## 🎯 Quick Answer

After uploading documents, **enable RAG in your chat** and ask questions naturally. The AI will search your documents and answer based on the content.

---

## 📋 Step-by-Step Guide

### Step 1: Upload Your Documents First

Before you can query, you need documents in the system:

1. Go to `http://<your-ip>:8080`
2. Upload your PDFs/documents (see [HOW-TO-UPLOAD-PDFS.md](HOW-TO-UPLOAD-PDFS.md))
3. Wait for "Indexed" status

### Step 2: Start a New Chat

1. Click **"New Chat"** or **"+"** button
2. You'll see a fresh chat interface

### Step 3: Enable RAG/Documents

Look for one of these options (depends on your Open-WebUI version):

**Option A: Toggle Switch**
- Look for **"Use Documents"** toggle (usually near message input)
- Turn it **ON** (should turn blue/green)

**Option B: Document Selector**
- Look for **"#"** or **"📄"** icon near message input
- Click it → Select which documents to use
- Or select **"All Documents"**

**Option C: Model Settings**
- Click the **model name** (e.g., "deepseek-r1:8b")
- Enable **"RAG"** or **"Knowledge Base"**
- Select documents

### Step 4: Ask Your Question

Simply type your question naturally! Examples:

```
What is this document about?

Summarize the main points from my documents

What does the document say about [specific topic]?

Find information about [keyword]

Compare what different documents say about [topic]

What are the key takeaways?
```

### Step 5: Review the Response

The AI will:
- ✅ Search your documents
- ✅ Find relevant sections
- ✅ Generate an answer based on those sections
- ✅ Show **sources** (which documents/pages were used)

---

## 💡 Example Queries

### General Questions

```
📝 "What is this document about?"
📝 "Give me a summary of all uploaded documents"
📝 "What are the main topics covered?"
📝 "List the key points from the documents"
```

### Specific Information

```
🔍 "What does the document say about pricing?"
🔍 "Find all mentions of 'machine learning'"
🔍 "What is the definition of [term]?"
🔍 "Explain the process described in section 3"
```

### Comparative Questions

```
⚖️ "Compare the approaches in document A vs document B"
⚖️ "What are the differences between X and Y?"
⚖️ "Which document discusses [topic] in more detail?"
```

### Extraction Questions

```
📊 "List all the statistics mentioned"
📊 "What are the dates mentioned in the documents?"
📊 "Extract all the names/companies mentioned"
📊 "What are the requirements listed?"
```

### Analysis Questions

```
🧠 "What are the pros and cons mentioned?"
🧠 "What problems does this document address?"
🧠 "What solutions are proposed?"
🧠 "What are the recommendations?"
```

---

## 🎨 Visual Flow

```
You                          RAG System                    AI Response
 |                                |                              |
 | 1. Type question               |                              |
 |------------------------------->|                              |
 |    "What is X?"                |                              |
 |                                |                              |
 |                                | 2. Convert to embedding      |
 |                                | 3. Search vector DB          |
 |                                | 4. Find top-5 chunks         |
 |                                |                              |
 |                                | 5. Send chunks + question    |
 |                                |----------------------------->|
 |                                |                              |
 |                                |                              | 6. Generate answer
 |                                |                              | 7. Add sources
 |                                |                              |
 | 8. Receive answer with sources |                              |
 |<-----------------------------------------------------------|
 |    "Based on document.pdf,                                  |
 |     page 5: X is..."                                        |
 |    Sources: [document.pdf, p.5]                             |
```

---

## 🔧 Advanced Query Techniques

### 1. Be Specific

❌ **Bad:** "Tell me about it"
✅ **Good:** "What are the three main benefits of solar energy mentioned in the document?"

### 2. Reference Context

❌ **Bad:** "What's the price?"
✅ **Good:** "What is the pricing structure for the enterprise plan?"

### 3. Ask Follow-up Questions

```
First: "What is machine learning?"
Then: "Can you give me examples from the document?"
Then: "What are the challenges mentioned?"
```

### 4. Request Specific Formats

```
"List the steps as a numbered list"
"Create a table comparing the features"
"Summarize in 3 bullet points"
"Explain in simple terms"
```

### 5. Combine Multiple Documents

```
"Compare what document A and document B say about climate change"
"Find common themes across all uploaded documents"
"Which document has the most information about [topic]?"
```

---

## 📊 Understanding RAG Responses

### Response Structure

```
[AI Answer based on your documents]

Sources:
📄 document1.pdf (Page 5, 12)
📄 document2.pdf (Page 3)
```

### What the Sources Mean

- **Document name**: Which file the information came from
- **Page numbers**: Specific pages referenced
- **Relevance**: Most relevant sources listed first

### Clicking Sources (if available)

Some Open-WebUI versions let you:
- Click on source links
- View the exact text chunk used
- Jump to that section of the document

---

## 🎯 Query Strategies by Document Type

### Technical Documentation

```
"What are the system requirements?"
"How do I configure [feature]?"
"What are the API endpoints?"
"Explain the architecture diagram"
```

### Research Papers

```
"What is the main hypothesis?"
"What methodology was used?"
"What were the key findings?"
"What are the limitations mentioned?"
```

### Business Documents

```
"What are the quarterly results?"
"Who are the key stakeholders?"
"What are the action items?"
"What is the timeline?"
```

### Legal Documents

```
"What are the terms and conditions?"
"What are the obligations of each party?"
"What are the termination clauses?"
"What are the liability limits?"
```

### Manuals/Guides

```
"How do I troubleshoot [problem]?"
"What are the step-by-step instructions for [task]?"
"What safety precautions are mentioned?"
"What tools are required?"
```

---

## 🚀 Pro Tips

### 1. Start Broad, Then Narrow

```
1st: "What topics are covered in this document?"
2nd: "Tell me more about [specific topic]"
3rd: "What are the details about [sub-topic]?"
```

### 2. Use Keywords from Your Documents

If your document uses specific terms, use those same terms in your questions.

### 3. Ask for Evidence

```
"What evidence supports this claim?"
"What examples are provided?"
"What data backs this up?"
```

### 4. Request Summaries at Different Levels

```
"Give me a one-sentence summary"
"Summarize in one paragraph"
"Provide a detailed summary"
```

### 5. Verify Information

```
"Is this information in the document?"
"Where in the document is this mentioned?"
"Can you quote the exact text?"
```

---

## 🐛 Troubleshooting

### "I don't have information about that"

**Possible causes:**
- Information not in your documents
- Documents not indexed yet
- RAG not enabled
- Query too vague

**Solutions:**
```bash
# Check if documents are indexed
# In WebUI: Go to documents list, check status

# Verify RAG is enabled
docker exec open-webui env | grep RAG

# Try rephrasing your question
# Be more specific
```

### Getting Generic Answers (Not from Your Docs)

**Problem:** AI answering from general knowledge, not your documents

**Solution:**
- Make sure **"Use Documents"** toggle is ON
- Try: "Based on the uploaded documents, what..."
- Try: "According to my documents, what..."

### Sources Not Showing

**Problem:** Answer provided but no sources listed

**Solution:**
```bash
# Check RAG configuration
docker logs open-webui 2>&1 | grep -i "rag\|source"

# Restart container
docker restart open-webui
```

### Slow Responses

**Problem:** Takes too long to answer

**Solution:**
```bash
# Reduce top-k (fewer chunks retrieved)
export RAG_TOP_K=3
sudo -E bash scripts/enable-rag.sh

# Or reduce chunk size
export CHUNK_SIZE=256
sudo -E bash scripts/enable-rag.sh
```

---

## 📱 Using RAG via API

### Python Example

```python
import requests

url = "http://your-ip:8080/api/chat"
headers = {
    "Authorization": "Bearer YOUR_API_KEY",
    "Content-Type": "application/json"
}

data = {
    "model": "deepseek-r1:8b",
    "messages": [
        {
            "role": "user",
            "content": "What is machine learning according to my documents?"
        }
    ],
    "use_rag": True,  # Enable RAG
    "rag_top_k": 5     # Number of chunks to retrieve
}

response = requests.post(url, json=data, headers=headers)
result = response.json()

print("Answer:", result['message']['content'])
print("Sources:", result.get('sources', []))
```

### cURL Example

```bash
curl -X POST http://your-ip:8080/api/chat \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "deepseek-r1:8b",
    "messages": [
      {
        "role": "user",
        "content": "Summarize my documents"
      }
    ],
    "use_rag": true
  }'
```

---

## 🎓 Best Practices

### DO ✅

- ✅ Upload documents before querying
- ✅ Wait for indexing to complete
- ✅ Enable "Use Documents" toggle
- ✅ Ask specific questions
- ✅ Use keywords from your documents
- ✅ Check sources in responses
- ✅ Ask follow-up questions
- ✅ Rephrase if answer is unclear

### DON'T ❌

- ❌ Ask questions without enabling RAG
- ❌ Query before documents are indexed
- ❌ Ask extremely vague questions
- ❌ Expect information not in your documents
- ❌ Ignore the sources provided
- ❌ Upload too many unrelated documents

---

## 📊 Query Performance

| Query Type | Response Time | Accuracy |
|------------|---------------|----------|
| Simple fact lookup | 1-3 seconds | High |
| Summary request | 3-5 seconds | High |
| Complex analysis | 5-10 seconds | Medium-High |
| Multi-document comparison | 5-15 seconds | Medium |

**Note:** First query may be slower (embedding model loading)

---

## 🔍 Example Session

```
You: "What documents do I have uploaded?"
AI: "You have 3 documents: report.pdf, guide.md, and data.txt"

You: "Summarize report.pdf"
AI: "The report discusses Q4 sales performance, showing 15% growth..."
Sources: [report.pdf, pages 1-3]

You: "What was the growth percentage?"
AI: "According to the report, the growth was 15% year-over-year."
Sources: [report.pdf, page 2]

You: "What factors contributed to this growth?"
AI: "The report identifies three main factors: 1) New product launches..."
Sources: [report.pdf, page 5]
```

---

## 🆘 Quick Help

```bash
# Check if RAG is working
bash scripts/test-rag.sh

# View RAG logs
docker logs open-webui 2>&1 | grep -i rag

# Restart RAG
docker restart open-webui

# Re-enable RAG
sudo bash scripts/enable-rag.sh
```

---

## 📚 Related Guides

- 📄 [How to Upload PDFs](HOW-TO-UPLOAD-PDFS.md)
- 🚀 [RAG Setup Guide](RAG-SETUP.md)
- ⚡ [Quick Reference](RAG-QUICK-REFERENCE.md)

---

**Start asking questions and let RAG find the answers in your documents!** 🎯
