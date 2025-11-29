#!/bin/bash
################################################################################
# RAG Testing Script
# Quick test to verify RAG functionality is working
################################################################################

set -e

echo "=========================================="
echo "🧪 RAG Functionality Test"
echo "=========================================="
echo ""

# Configuration
WEBUI_URL="${WEBUI_URL:-http://localhost:8080}"
TEST_DOC_PATH="${TEST_DOC_PATH:-/tmp/test-rag-doc.txt}"

echo "Configuration:"
echo "  WebUI URL: $WEBUI_URL"
echo "  Test Document: $TEST_DOC_PATH"
echo ""

################################################################################
# Test 1: Check Container Status
################################################################################

echo "Test 1: Checking Open-WebUI container..."
echo "-----------------------------------"

if docker ps | grep -q open-webui; then
    echo "✅ Open-WebUI container is running"
    
    # Get container details
    CONTAINER_ID=$(docker ps --filter name=open-webui --format "{{.ID}}")
    echo "   Container ID: $CONTAINER_ID"
    
    # Check uptime
    UPTIME=$(docker ps --filter name=open-webui --format "{{.Status}}")
    echo "   Status: $UPTIME"
else
    echo "❌ Open-WebUI container is NOT running"
    echo "   Run: docker ps -a | grep open-webui"
    exit 1
fi

echo ""

################################################################################
# Test 2: Check RAG Environment Variables
################################################################################

echo "Test 2: Checking RAG configuration..."
echo "-----------------------------------"

# Check environment variables
RAG_CONFIG=$(docker inspect open-webui | grep -E "RAG_|CHUNK_" | head -10)

if [ -n "$RAG_CONFIG" ]; then
    echo "✅ RAG environment variables detected:"
    docker inspect open-webui --format '{{range .Config.Env}}{{println .}}{{end}}' | grep -E "RAG_|CHUNK_" | sed 's/^/   /'
else
    echo "⚠️  No RAG environment variables found"
    echo "   RAG may not be configured"
fi

echo ""

################################################################################
# Test 3: Check Vector Database Volume
################################################################################

echo "Test 3: Checking vector database volume..."
echo "-----------------------------------"

if docker volume inspect chroma-data &>/dev/null; then
    echo "✅ chroma-data volume exists"
    
    # Get volume details
    VOLUME_SIZE=$(docker system df -v | grep chroma-data | awk '{print $3}')
    if [ -n "$VOLUME_SIZE" ]; then
        echo "   Size: $VOLUME_SIZE"
    fi
else
    echo "⚠️  chroma-data volume not found"
    echo "   RAG may not be properly configured"
fi

echo ""

################################################################################
# Test 4: Check HTTP Endpoint
################################################################################

echo "Test 4: Testing HTTP endpoint..."
echo "-----------------------------------"

HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" $WEBUI_URL)

if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "302" ]; then
    echo "✅ WebUI is responding (HTTP $HTTP_CODE)"
else
    echo "⚠️  WebUI returned HTTP $HTTP_CODE"
    echo "   May still be starting up"
fi

echo ""

################################################################################
# Test 5: Check Container Logs for RAG
################################################################################

echo "Test 5: Checking container logs for RAG..."
echo "-----------------------------------"

# Check for RAG-related log entries
RAG_LOGS=$(docker logs open-webui 2>&1 | grep -i "rag\|chroma\|embedding" | tail -5)

if [ -n "$RAG_LOGS" ]; then
    echo "✅ RAG-related log entries found:"
    echo "$RAG_LOGS" | sed 's/^/   /'
else
    echo "ℹ️  No RAG-specific logs found (may be normal)"
fi

echo ""

################################################################################
# Test 6: Create Test Document
################################################################################

echo "Test 6: Creating test document..."
echo "-----------------------------------"

cat > "$TEST_DOC_PATH" <<'EOF'
RAG Test Document
=================

This is a test document for verifying RAG functionality.

Key Information:
- The capital of France is Paris
- The speed of light is approximately 299,792,458 meters per second
- Water boils at 100 degrees Celsius at sea level
- The Earth orbits the Sun once every 365.25 days

Test Query Answers:
Q: What is the capital of France?
A: Paris

Q: What is the speed of light?
A: Approximately 299,792,458 meters per second

This document was created on $(date) for RAG testing purposes.
EOF

if [ -f "$TEST_DOC_PATH" ]; then
    echo "✅ Test document created"
    echo "   Path: $TEST_DOC_PATH"
    echo "   Size: $(wc -c < "$TEST_DOC_PATH") bytes"
else
    echo "❌ Failed to create test document"
fi

echo ""

################################################################################
# Test 7: Check Embedding Model
################################################################################

echo "Test 7: Checking embedding model..."
echo "-----------------------------------"

# Check if embedding model directory exists
if docker exec open-webui test -d /app/backend/data/cache/embedding 2>/dev/null; then
    echo "✅ Embedding cache directory exists"
    
    # Try to list models
    MODEL_COUNT=$(docker exec open-webui find /app/backend/data/cache/embedding -type f 2>/dev/null | wc -l)
    if [ "$MODEL_COUNT" -gt 0 ]; then
        echo "   Found $MODEL_COUNT model file(s)"
    else
        echo "   No models cached yet (will download on first use)"
    fi
else
    echo "ℹ️  Embedding cache not yet created"
    echo "   Will be created on first document upload"
fi

echo ""

################################################################################
# Test 8: Check Available Storage
################################################################################

echo "Test 8: Checking available storage..."
echo "-----------------------------------"

# Check disk space
DISK_USAGE=$(df -h / | tail -1 | awk '{print $5}' | sed 's/%//')

if [ "$DISK_USAGE" -lt 80 ]; then
    echo "✅ Sufficient disk space available"
    df -h / | tail -1 | awk '{print "   Used: "$5" of "$2}'
else
    echo "⚠️  Disk usage is high: ${DISK_USAGE}%"
    echo "   Consider cleaning up or expanding storage"
fi

echo ""

################################################################################
# Test 9: Check Memory Usage
################################################################################

echo "Test 9: Checking memory usage..."
echo "-----------------------------------"

# Get container memory stats
MEMORY_STATS=$(docker stats --no-stream --format "{{.MemUsage}}" open-webui)

if [ -n "$MEMORY_STATS" ]; then
    echo "✅ Container memory usage: $MEMORY_STATS"
else
    echo "ℹ️  Could not retrieve memory stats"
fi

echo ""

################################################################################
# Summary
################################################################################

echo "=========================================="
echo "📊 Test Summary"
echo "=========================================="
echo ""

# Count passed tests
PASSED=0
TOTAL=9

# Test results
if docker ps | grep -q open-webui; then PASSED=$((PASSED+1)); fi
if docker inspect open-webui | grep -q "RAG_"; then PASSED=$((PASSED+1)); fi
if docker volume inspect chroma-data &>/dev/null; then PASSED=$((PASSED+1)); fi
if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "302" ]; then PASSED=$((PASSED+1)); fi
if [ -n "$RAG_LOGS" ]; then PASSED=$((PASSED+1)); fi
if [ -f "$TEST_DOC_PATH" ]; then PASSED=$((PASSED+1)); fi
if docker exec open-webui test -d /app/backend/data/cache/embedding 2>/dev/null; then PASSED=$((PASSED+1)); fi
if [ "$DISK_USAGE" -lt 80 ]; then PASSED=$((PASSED+1)); fi
if [ -n "$MEMORY_STATS" ]; then PASSED=$((PASSED+1)); fi

echo "Tests Passed: $PASSED/$TOTAL"
echo ""

if [ $PASSED -eq $TOTAL ]; then
    echo "✅ All tests passed! RAG is ready to use."
    echo ""
    echo "Next Steps:"
    echo "1. Access WebUI at $WEBUI_URL"
    echo "2. Go to Settings → Documents"
    echo "3. Upload the test document: $TEST_DOC_PATH"
    echo "4. Enable 'Use Documents' in chat"
    echo "5. Ask: 'What is the capital of France?'"
    echo ""
elif [ $PASSED -ge 6 ]; then
    echo "⚠️  Most tests passed. RAG should work but may need attention."
    echo ""
    echo "Check the warnings above and:"
    echo "- Review container logs: docker logs open-webui"
    echo "- Restart if needed: docker restart open-webui"
    echo ""
else
    echo "❌ Several tests failed. RAG may not be working correctly."
    echo ""
    echo "Troubleshooting:"
    echo "1. Check container logs: docker logs open-webui"
    echo "2. Verify configuration: docker inspect open-webui"
    echo "3. Re-run setup: sudo bash scripts/enable-rag.sh"
    echo ""
fi

echo "=========================================="
echo ""

# Cleanup
echo "Cleanup: Test document saved at $TEST_DOC_PATH"
echo "You can upload this file to test RAG functionality."
echo ""
