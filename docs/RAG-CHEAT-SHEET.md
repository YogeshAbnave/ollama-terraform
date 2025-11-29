# RAG Query Cheat Sheet

## 🚀 Quick Start (3 Steps)

```
1. Upload documents → Wait for "Indexed"
2. Enable "Use Documents" toggle in chat
3. Ask your question!
```

---

## 💬 Question Templates

### 📖 General Understanding
```
"What is this document about?"
"Summarize the main points"
"What topics are covered?"
"Give me an overview"
```

### 🔍 Find Specific Info
```
"What does it say about [topic]?"
"Find information on [keyword]"
"Where is [term] mentioned?"
"What is the definition of [X]?"
```

### 📊 Extract Data
```
"List all [items] mentioned"
"What are the dates/numbers?"
"Extract the key statistics"
"What are the requirements?"
```

### ⚖️ Compare & Analyze
```
"Compare [A] and [B]"
"What are the pros and cons?"
"What are the differences?"
"Which document discusses [topic]?"
```

### 🎯 Specific Requests
```
"Explain [concept] in simple terms"
"Give me step-by-step instructions"
"What are the 3 main takeaways?"
"Create a bullet point summary"
```

---

## ✅ Good Questions vs ❌ Bad Questions

| ❌ Bad (Too Vague) | ✅ Good (Specific) |
|-------------------|-------------------|
| "Tell me about it" | "What are the three main benefits mentioned?" |
| "What's the price?" | "What is the pricing for the enterprise plan?" |
| "Summarize" | "Summarize the key findings in 3 bullet points" |
| "What does it say?" | "What does section 2 say about security?" |

---

## 🎯 Query by Document Type

### 📄 Technical Docs
```
"What are the system requirements?"
"How do I configure [feature]?"
"What are the API endpoints?"
"Show me the troubleshooting steps"
```

### 📊 Reports
```
"What are the key metrics?"
"What were the results?"
"What are the recommendations?"
"What is the conclusion?"
```

### 📚 Research Papers
```
"What is the main hypothesis?"
"What methodology was used?"
"What were the findings?"
"What are the limitations?"
```

### 📋 Manuals
```
"How do I [task]?"
"What tools are needed?"
"What are the safety warnings?"
"Show me the installation steps"
```

---

## 🔧 Troubleshooting Queries

| Problem | Solution |
|---------|----------|
| "No information found" | Be more specific, check if doc is indexed |
| Generic answers | Enable "Use Documents" toggle |
| No sources shown | Restart: `docker restart open-webui` |
| Slow responses | Reduce RAG_TOP_K to 3 |

---

## 💡 Pro Tips

```
✅ Start broad → narrow down
✅ Use keywords from your documents
✅ Ask follow-up questions
✅ Check the sources provided
✅ Rephrase if unclear
```

---

## 🎨 Response Format Requests

```
"List as bullet points"
"Create a table"
"Explain in 3 sentences"
"Give me a detailed breakdown"
"Summarize in one paragraph"
```

---

## 🔍 Verification Questions

```
"Is this mentioned in the document?"
"Where is this information located?"
"Can you quote the exact text?"
"What page is this on?"
"Which document says this?"
```

---

## 📱 Quick Commands

```bash
# Test RAG
bash scripts/test-rag.sh

# Check status
cat /home/ubuntu/rag-status.txt

# View logs
docker logs -f open-webui

# Restart
docker restart open-webui
```

---

## 🎯 Example Flow

```
1. "What documents do I have?"
   → Lists your uploaded documents

2. "Summarize report.pdf"
   → Gives overview with sources

3. "What about the Q4 results?"
   → Specific info from that section

4. "Compare with Q3"
   → Comparative analysis

5. "What's the growth percentage?"
   → Exact data extraction
```

---

## 📚 Full Guides

- 📘 [Complete Query Guide](HOW-TO-QUERY-RAG.md)
- 📄 [Upload PDFs](HOW-TO-UPLOAD-PDFS.md)
- 🚀 [RAG Setup](RAG-SETUP.md)

---

**Remember: Enable "Use Documents" toggle before asking!** 🎯
