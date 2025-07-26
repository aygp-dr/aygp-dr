#!/bin/bash
# capture-ollama-samples.sh - Capture real Ollama API responses

OUTPUT_DIR="ollama-artifacts"
mkdir -p "$OUTPUT_DIR"

echo "=== Capturing Ollama Response Samples ==="
echo "Timestamp: $(date -u +"%Y-%m-%dT%H:%M:%SZ")" | tee "$OUTPUT_DIR/metadata.txt"
echo ""

# Capture Ollama version
echo "Ollama Version:" | tee -a "$OUTPUT_DIR/metadata.txt"
ollama version 2>&1 | tee -a "$OUTPUT_DIR/metadata.txt" || echo "ollama CLI not available" | tee -a "$OUTPUT_DIR/metadata.txt"
echo ""

# List available models
echo "Available Models:" | tee -a "$OUTPUT_DIR/metadata.txt"
curl -s http://localhost:11434/api/tags | jq '.' > "$OUTPUT_DIR/available-models.json" 2>/dev/null || echo "Failed to fetch models"
cat "$OUTPUT_DIR/available-models.json" | jq -r '.models[]?.name' 2>/dev/null | tee -a "$OUTPUT_DIR/metadata.txt"
echo ""

# Test 1: Basic generation
echo "Test 1: Basic text generation"
cat > "$OUTPUT_DIR/request-basic.json" << EOF
{
  "model": "llama3.2:3b",
  "prompt": "What is Scheme programming language in one sentence?",
  "stream": false
}
EOF

curl -s -X POST http://localhost:11434/api/generate \
  -H 'Content-Type: application/json' \
  -d @"$OUTPUT_DIR/request-basic.json" \
  > "$OUTPUT_DIR/response-basic.json"

echo "Saved to: $OUTPUT_DIR/response-basic.json"
jq '.' "$OUTPUT_DIR/response-basic.json" 2>/dev/null || cat "$OUTPUT_DIR/response-basic.json"
echo ""

# Test 2: Structured output (topics)
echo "Test 2: Structured output for topics"
cat > "$OUTPUT_DIR/request-structured.json" << EOF
{
  "model": "llama3.2:3b",
  "prompt": "Generate exactly 5 GitHub repository topics for a Scheme project that uses Ollama for LLM integration, GitHub API for repository management, and includes validation frameworks. Return ONLY valid JSON in this format: {\"topics\": [\"topic1\", \"topic2\", \"topic3\", \"topic4\", \"topic5\"]}",
  "stream": false,
  "format": {
    "type": "object",
    "properties": {
      "topics": {
        "type": "array",
        "items": {"type": "string"},
        "minItems": 5,
        "maxItems": 5
      }
    },
    "required": ["topics"]
  }
}
EOF

curl -s -X POST http://localhost:11434/api/generate \
  -H 'Content-Type: application/json' \
  -d @"$OUTPUT_DIR/request-structured.json" \
  > "$OUTPUT_DIR/response-structured.json"

echo "Saved to: $OUTPUT_DIR/response-structured.json"
jq '.' "$OUTPUT_DIR/response-structured.json" 2>/dev/null || cat "$OUTPUT_DIR/response-structured.json"
echo ""

# Test 3: Complex nested JSON
echo "Test 3: Complex analysis with nested JSON"
cat > "$OUTPUT_DIR/request-complex.json" << EOF
{
  "model": "llama3.2:3b",
  "prompt": "Analyze a GitHub repository and return a JSON object with: name, primary_language, topics array, and metrics object containing stars and forks. Example: {\"name\": \"repo\", \"primary_language\": \"scheme\", \"topics\": [\"a\", \"b\"], \"metrics\": {\"stars\": 10, \"forks\": 2}}",
  "stream": false
}
EOF

curl -s -X POST http://localhost:11434/api/generate \
  -H 'Content-Type: application/json' \
  -d @"$OUTPUT_DIR/request-complex.json" \
  > "$OUTPUT_DIR/response-complex.json"

echo "Saved to: $OUTPUT_DIR/response-complex.json"
jq '.' "$OUTPUT_DIR/response-complex.json" 2>/dev/null || cat "$OUTPUT_DIR/response-complex.json"
echo ""

# Test 4: Chat API
echo "Test 4: Chat API for topic generation"
cat > "$OUTPUT_DIR/request-chat.json" << EOF
{
  "model": "llama3.2:3b",
  "messages": [
    {
      "role": "system",
      "content": "You are a GitHub topic generator. Always respond with exactly 5 lowercase topics with hyphens, no spaces."
    },
    {
      "role": "user", 
      "content": "Generate topics for a Scheme project with Ollama integration"
    }
  ],
  "stream": false
}
EOF

curl -s -X POST http://localhost:11434/api/chat \
  -H 'Content-Type: application/json' \
  -d @"$OUTPUT_DIR/request-chat.json" \
  > "$OUTPUT_DIR/response-chat.json"

echo "Saved to: $OUTPUT_DIR/response-chat.json"
jq '.' "$OUTPUT_DIR/response-chat.json" 2>/dev/null || cat "$OUTPUT_DIR/response-chat.json"
echo ""

# Test 5: Streaming response (capture first few chunks)
echo "Test 5: Streaming response (first 5 chunks)"
cat > "$OUTPUT_DIR/request-stream.json" << EOF
{
  "model": "llama3.2:3b",
  "prompt": "List 3 Scheme features",
  "stream": true
}
EOF

curl -s -X POST http://localhost:11434/api/generate \
  -H 'Content-Type: application/json' \
  -d @"$OUTPUT_DIR/request-stream.json" \
  | head -5 > "$OUTPUT_DIR/response-stream-chunks.jsonl"

echo "Saved to: $OUTPUT_DIR/response-stream-chunks.jsonl"
cat "$OUTPUT_DIR/response-stream-chunks.jsonl"
echo ""

echo "=== Summary ==="
echo "All samples saved to: $OUTPUT_DIR/"
ls -la "$OUTPUT_DIR/"