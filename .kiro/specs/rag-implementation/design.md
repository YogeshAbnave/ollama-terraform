# RAG Implementation Design Document

## Overview

This design document describes the architecture and implementation approach for adding Retrieval-Augmented Generation (RAG) capabilities to the existing Ollama + Open-WebUI AWS deployment. The RAG system will enable users to upload documents, automatically index them into a vector database, and retrieve relevant context when querying the AI models.

The implementation leverages Open-WebUI's built-in RAG features, ChromaDB as the vector database, and sentence-transformers for embeddings. All components will be automatically deployed via the existing Terraform and user-data infrastructure.

## Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        EC2 Instance                          │
│                                                              │
│  ┌──────────────┐      ┌──────────────┐    ┌─────────────┐ │
│  │              │      │              │    │             │ │
│  │  Open-WebUI  │◄────►│   ChromaDB   │    │   Ollama    │ │
│  │  (Port 8080) │      │ (Embedded)   │    │ (Port 11434)│ │
│  │              │      │              │    │             │ │
│  └──────┬───────┘      └──────┬───────┘    └──────┬──────┘ │
│         │                     │                   │        │
│         │                     │                   │        │
│  ┌──────▼─────────────────────▼───────────────────▼──────┐ │
│  │                                                        │ │
│  │              Persistent Volume Storage                │ │
│  │         /app/backend/data (Open-WebUI data)          │ │
│  │         /chroma/data (Vector DB storage)             │ │
│  │                                                        │ │
│  └────────────────────────────────────────────────────────┘ │
│                                                              │
└─────────────────────────────────────────────────────────────┘
                           │
                           │ HTTPS/HTTP
                           ▼
                    ┌──────────────┐
                    │    Users     │
                    └──────────────┘
```

### Component Interaction Flow

1. **Document Upload Flow**:
   - User uploads document via Open-WebUI interface
   - Open-WebUI processes document (parsing, chunking)
   - Text chunks are sent to embedding model
   - Embeddings stored in ChromaDB with metadata
   - User receives confirmation

2. **Query Flow**:
   - User submits query via Open-WebUI
   - Query is embedded using same embedding model
   - ChromaDB performs similarity search
   - Top-k relevant chunks retrieved
   - Chunks + query sent to Ollama
   - Ollama generates response with context
   - Response returned with source attribution

## Components and Interfaces

### 1. Open-WebUI (Frontend + Backend)

**Responsibilities**:
- User interface for document upload and management
- Document parsing and chunking
- Integration with ChromaDB for storage/retrieval
- Query orchestration and response formatting
- Source attribution display

**Configuration**:
- Environment variables for RAG settings
- Volume mount for persistent data
- Network access to Ollama and ChromaDB

**Key Settings**:
```bash
ENABLE_RAG_WEB_SEARCH=false
ENABLE_RAG_LOCAL_WEB_FETCH=true
RAG_EMBEDDING_MODEL=sentence-transformers/all-MiniLM-L6-v2
RAG_TOP_K=5
CHUNK_SIZE=512
CHUNK_OVERLAP=50
```

### 2. ChromaDB (Vector Database)

**Responsibilities**:
- Store document embeddings
- Perform similarity search
- Manage collections and metadata
- Persist data to disk

**Deployment Mode**: Embedded (runs within Open-WebUI process)

**Storage**: Docker volume mounted to `/chroma/data`

**Configuration**:
- Persistent storage enabled
- Anonymous telemetry disabled
- Memory limit: 2GB

### 3. Embedding Model

**Model**: `sentence-transformers/all-MiniLM-L6-v2`

**Characteristics**:
- Size: ~80MB
- Dimensions: 384
- Fast inference (~50ms per chunk)
- Good balance of quality and performance

**Deployment**: Downloaded automatically by Open-WebUI on first use

### 4. Document Processors

**Supported Formats**:
- **PDF**: PyPDF2 or pdfplumber for text extraction
- **TXT**: Direct text processing
- **Markdown**: Markdown parser preserving structure
- **DOCX**: python-docx for Word document parsing

**Chunking Strategy**:
- Recursive character text splitter
- Chunk size: 512 tokens (configurable)
- Overlap: 50 tokens (configurable)
- Preserve sentence boundaries where possible

### 5. Ollama Integration

**Role**: Generate responses using retrieved context

**Context Injection**: Retrieved chunks prepended to user query as system context

**Prompt Template**:
```
Context from documents:
{retrieved_chunks}

User question: {user_query}

Please answer based on the provided context. If the context doesn't contain relevant information, say so.
```

## Data Models

### Document Metadata

```json
{
  "id": "uuid-v4",
  "filename": "document.pdf",
  "file_type": "pdf",
  "upload_date": "2024-11-29T10:30:00Z",
  "user_id": "user-uuid",
  "size_bytes": 1048576,
  "chunk_count": 42,
  "status": "indexed",
  "collection_name": "user_documents"
}
```

### Document Chunk

```json
{
  "id": "chunk-uuid",
  "document_id": "doc-uuid",
  "content": "The actual text content of the chunk...",
  "embedding": [0.123, -0.456, ...],
  "metadata": {
    "source": "document.pdf",
    "page": 5,
    "chunk_index": 12,
    "char_start": 5000,
    "char_end": 5512
  }
}
```

### Retrieval Result

```json
{
  "chunks": [
    {
      "content": "Retrieved text...",
      "score": 0.89,
      "metadata": {
        "source": "document.pdf",
        "page": 5
      }
    }
  ],
  "query": "user question",
  "retrieval_time_ms": 45
}
```

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system-essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property 1: Document Upload Completeness
*For any* valid document uploaded to the system, all text content should be successfully extracted and indexed, such that querying for content from that document returns relevant results.
**Validates: Requirements 1.1, 1.2, 1.3, 1.4**

### Property 2: Embedding Consistency
*For any* text chunk, generating embeddings multiple times with the same model should produce identical or nearly identical vectors (within floating-point precision).
**Validates: Requirements 1.3**

### Property 3: Retrieval Relevance
*For any* query and document collection, the top-k retrieved chunks should have similarity scores greater than or equal to all non-retrieved chunks.
**Validates: Requirements 2.2, 2.3**

### Property 4: Source Attribution Accuracy
*For any* retrieved chunk included in a response, the source attribution should correctly identify the original document and location.
**Validates: Requirements 2.5**

### Property 5: Document Deletion Completeness
*For any* document deleted by a user, subsequent queries should not retrieve any chunks from that document.
**Validates: Requirements 4.3**

### Property 6: Configuration Bounds
*For any* RAG configuration parameter (chunk_size, top_k, etc.), the system should enforce valid ranges and reject invalid values.
**Validates: Requirements 5.1, 5.2, 5.3, 5.4**

### Property 7: Resource Limits
*For any* workload, the Vector Database memory usage should not exceed the configured maximum limit.
**Validates: Requirements 10.1, 10.2**

### Property 8: Format Support
*For any* supported file format (PDF, TXT, MD, DOCX), the system should successfully parse and index the document, and for any unsupported format, the system should reject with an error.
**Validates: Requirements 6.1, 6.2, 6.3, 6.4, 6.5**

### Property 9: Chunk Overlap Preservation
*For any* document chunked with overlap, consecutive chunks should share content equal to the configured overlap size.
**Validates: Requirements 5.2**

### Property 10: Retrieval Idempotence
*For any* query executed multiple times against an unchanged document collection, the retrieved chunks should be identical.
**Validates: Requirements 2.2, 2.3**

## Error Handling

### Document Upload Errors

**Scenario**: Unsupported file format
- **Detection**: File extension validation
- **Response**: HTTP 400 with clear error message
- **Recovery**: User uploads supported format

**Scenario**: Document parsing failure
- **Detection**: Exception during text extraction
- **Response**: Mark document as "failed" status
- **Recovery**: Retry with different parser or manual intervention

**Scenario**: Embedding generation failure
- **Detection**: Model inference error
- **Response**: Log error, mark chunks as "pending"
- **Recovery**: Retry embedding generation

### Retrieval Errors

**Scenario**: Vector database unavailable
- **Detection**: Connection timeout or error
- **Response**: Fallback to non-RAG mode
- **Recovery**: Automatic retry with exponential backoff

**Scenario**: No relevant documents found
- **Detection**: All similarity scores below threshold
- **Response**: Inform user, proceed without context
- **Recovery**: User can adjust threshold or upload more documents

**Scenario**: Embedding model unavailable
- **Detection**: Model loading failure
- **Response**: Disable RAG temporarily
- **Recovery**: Automatic model download retry

### Resource Errors

**Scenario**: Disk space exhausted
- **Detection**: Storage monitoring
- **Response**: Reject new uploads, alert admin
- **Recovery**: Delete old documents or expand storage

**Scenario**: Memory limit exceeded
- **Detection**: Memory monitoring
- **Response**: Trigger garbage collection, limit concurrent operations
- **Recovery**: Automatic recovery after memory release

## Testing Strategy

### Unit Testing

**Document Processing Tests**:
- Test PDF text extraction with sample PDFs
- Test chunking with various text sizes
- Test overlap calculation
- Test metadata extraction

**Embedding Tests**:
- Test embedding generation for sample texts
- Test embedding dimension consistency
- Test batch embedding processing

**Retrieval Tests**:
- Test similarity search with known queries
- Test top-k filtering
- Test threshold filtering

### Property-Based Testing

**Framework**: Hypothesis (Python)

**Test Configuration**: Minimum 100 iterations per property

**Property Tests**:

1. **Property 1 Test**: Generate random documents, upload them, verify all content is searchable
2. **Property 2 Test**: Generate random text, embed multiple times, verify consistency
3. **Property 3 Test**: Generate random queries and documents, verify top-k ordering
4. **Property 4 Test**: Generate random documents with metadata, verify attribution accuracy
5. **Property 5 Test**: Generate random documents, delete them, verify no retrieval
6. **Property 6 Test**: Generate random config values, verify bounds enforcement
7. **Property 7 Test**: Generate random workloads, verify memory limits
8. **Property 8 Test**: Generate files of various formats, verify parsing behavior
9. **Property 9 Test**: Generate random documents, verify chunk overlap
10. **Property 10 Test**: Generate random queries, execute multiple times, verify idempotence

Each property-based test must be tagged with:
`# Feature: rag-implementation, Property X: [property description]`

### Integration Testing

**End-to-End Tests**:
- Upload document → Query → Verify response includes context
- Upload multiple documents → Query → Verify correct source attribution
- Delete document → Query → Verify document not retrieved
- Configure parameters → Verify behavior changes

**Performance Tests**:
- Measure document indexing time
- Measure query latency
- Measure memory usage under load
- Verify resource limits enforced

## Deployment Strategy

### Infrastructure Changes

**Terraform Updates**:
- No changes required to EC2 instance configuration
- Existing t3.xlarge instance sufficient for RAG workload
- Storage size (50GB) adequate for moderate document collections

**User-Data Script Updates**:
- Add ChromaDB installation (embedded, no separate install needed)
- Configure Open-WebUI with RAG environment variables
- Download embedding model on first boot
- Create persistent volumes for vector database

### Docker Configuration

**Updated Open-WebUI Container**:
```bash
docker run -d \
  --network host \
  --name open-webui \
  -p 8080:8080 \
  -e OLLAMA_BASE_URL=http://127.0.0.1:11434 \
  -e ENABLE_RAG_WEB_SEARCH=false \
  -e RAG_EMBEDDING_MODEL=sentence-transformers/all-MiniLM-L6-v2 \
  -e RAG_TOP_K=5 \
  -e CHUNK_SIZE=512 \
  -e CHUNK_OVERLAP=50 \
  -v open-webui:/app/backend/data \
  -v chroma-data:/chroma/data \
  --add-host=host.docker.internal:host-gateway \
  --restart always \
  ghcr.io/open-webui/open-webui:main
```

### Configuration Management

**Environment Variables** (added to user-data.sh.tpl):
```bash
# RAG Configuration
ENABLE_RAG_WEB_SEARCH=false
RAG_EMBEDDING_MODEL=sentence-transformers/all-MiniLM-L6-v2
RAG_TOP_K=${rag_top_k}
CHUNK_SIZE=${chunk_size}
CHUNK_OVERLAP=${chunk_overlap}
```

**Terraform Variables** (added to terraform-ec2.tf):
```hcl
variable "rag_enabled" {
  description = "Enable RAG features"
  type        = bool
  default     = true
}

variable "rag_top_k" {
  description = "Number of chunks to retrieve"
  type        = number
  default     = 5
}

variable "chunk_size" {
  description = "Document chunk size in tokens"
  type        = number
  default     = 512
}

variable "chunk_overlap" {
  description = "Overlap between chunks in tokens"
  type        = number
  default     = 50
}
```

## Monitoring and Observability

### Metrics to Track

**Document Metrics**:
- Total documents indexed
- Total chunks stored
- Average chunks per document
- Indexing success/failure rate

**Query Metrics**:
- Queries per minute
- Average retrieval latency
- Average number of chunks retrieved
- Cache hit rate (if caching implemented)

**Resource Metrics**:
- Vector database memory usage
- Vector database disk usage
- Embedding model memory usage
- Query processing CPU usage

### Logging Strategy

**Log Levels**:
- **INFO**: Document uploads, successful queries
- **WARNING**: Slow queries, approaching resource limits
- **ERROR**: Failed uploads, retrieval errors, system errors

**Log Format**:
```json
{
  "timestamp": "2024-11-29T10:30:00Z",
  "level": "INFO",
  "component": "rag",
  "action": "document_indexed",
  "document_id": "uuid",
  "chunk_count": 42,
  "duration_ms": 1250
}
```

### Health Checks

**Endpoints**:
- `/health/rag` - Overall RAG system health
- `/health/vectordb` - ChromaDB connectivity
- `/health/embeddings` - Embedding model availability

**Health Check Criteria**:
- Vector database responsive (< 100ms ping)
- Embedding model loaded
- Disk space available (> 10% free)
- Memory usage within limits

## Security Considerations

### Document Access Control

- Documents scoped to user accounts
- No cross-user document access
- Admin can view all documents (optional)

### Data Privacy

- Documents stored locally on EC2 instance
- No external API calls for embeddings (local model)
- Vector database not exposed externally

### Input Validation

- File size limits (default 10MB per document)
- File type whitelist
- Sanitize filenames
- Validate chunk parameters

## Performance Optimization

### Caching Strategy

**Query Cache**:
- Cache query embeddings for repeated queries
- TTL: 1 hour
- Max size: 1000 entries

**Chunk Cache**:
- Cache frequently retrieved chunks
- LRU eviction policy
- Max size: 500 chunks

### Batch Processing

- Batch embed multiple chunks together
- Batch size: 32 chunks
- Reduces model loading overhead

### Indexing Optimization

- Process large documents asynchronously
- Show progress indicator to user
- Allow background indexing

## Future Enhancements

### Phase 2 Features

1. **Hybrid Search**: Combine semantic and keyword search
2. **Re-ranking**: Re-rank retrieved chunks for better relevance
3. **Multi-modal RAG**: Support images and tables
4. **Conversation Memory**: Remember previous queries in session
5. **Advanced Chunking**: Semantic chunking based on topics

### Scalability Considerations

- Support for external vector databases (Qdrant, Weaviate)
- Distributed indexing for large document collections
- Query result caching with Redis
- Load balancing for multiple instances

## Migration and Rollback

### Deployment Plan

1. Update user-data.sh.tpl with RAG configuration
2. Update terraform-ec2.tf with new variables
3. Deploy to new EC2 instance (or update existing)
4. Verify RAG functionality
5. Update documentation

### Rollback Plan

If RAG causes issues:
1. Set `ENABLE_RAG=false` environment variable
2. Restart Open-WebUI container
3. System reverts to non-RAG mode
4. No data loss (documents preserved)

### Data Migration

- No migration needed for new deployments
- Existing deployments: Documents must be re-uploaded
- Vector database starts empty

## Success Criteria

The RAG implementation is successful when:

1. ✅ Users can upload PDF, TXT, MD, DOCX documents
2. ✅ Documents are automatically indexed within 30 seconds
3. ✅ Queries retrieve relevant context with >80% accuracy
4. ✅ Source attribution correctly identifies documents
5. ✅ System operates within resource limits (2GB RAM for vector DB)
6. ✅ Query latency < 500ms for typical queries
7. ✅ All property-based tests pass
8. ✅ Integration with Open-WebUI is seamless
9. ✅ Deployment is fully automated via Terraform
10. ✅ Documentation is complete and accurate
