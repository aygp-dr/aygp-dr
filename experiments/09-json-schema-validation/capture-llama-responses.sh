#!/bin/bash
# capture-llama-responses.sh - Capture various response types from Llama 3.2

set -e

OUTPUT_DIR="llama-responses"
mkdir -p "$OUTPUT_DIR"

echo "=== Capturing Llama 3.2 Response Examples ==="
echo "Timestamp: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
echo ""

# 1. Basic Generate Response
echo "1. Basic text generation..."
cat > "$OUTPUT_DIR/01-generate-request.json" << 'EOF'
{
  "model": "llama3.2:3b",
  "prompt": "What is functional programming?",
  "stream": false,
  "options": {
    "temperature": 0.7
  }
}
EOF

curl -s -X POST http://localhost:11434/api/generate \
  -H 'Content-Type: application/json' \
  -d @"$OUTPUT_DIR/01-generate-request.json" \
  | jq '.' > "$OUTPUT_DIR/01-generate-response.json"

echo "✓ Saved: $OUTPUT_DIR/01-generate-response.json"

# 2. Structured Output (Topics)
echo -e "\n2. Structured output for topics..."
cat > "$OUTPUT_DIR/02-structured-request.json" << 'EOF'
{
  "model": "llama3.2:3b",
  "prompt": "Analyze this GitHub repository that contains Scheme code for Ollama integration, GitHub API clients, and validation frameworks. Generate exactly 5 relevant topics. Return ONLY valid JSON: {\"topics\": [\"topic1\", \"topic2\", \"topic3\", \"topic4\", \"topic5\"]}",
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
  -d @"$OUTPUT_DIR/02-structured-request.json" \
  | jq '.' > "$OUTPUT_DIR/02-structured-response.json"

echo "✓ Saved: $OUTPUT_DIR/02-structured-response.json"

# 3. Function Calling Simulation (OpenAI style)
echo -e "\n3. Function calling (OpenAI style)..."
cat > "$OUTPUT_DIR/03-function-request.json" << 'EOF'
{
  "model": "llama3.2:3b",
  "prompt": "You need to search for Scheme repositories on GitHub. Call the search_repositories function with these parameters: language='scheme', sort='stars', limit=10. Return your response as JSON in this format: {\"function_call\": {\"name\": \"search_repositories\", \"arguments\": {\"language\": \"scheme\", \"sort\": \"stars\", \"limit\": 10}}}",
  "stream": false
}
EOF

curl -s -X POST http://localhost:11434/api/generate \
  -H 'Content-Type: application/json' \
  -d @"$OUTPUT_DIR/03-function-request.json" \
  | jq '.' > "$OUTPUT_DIR/03-function-response.json"

echo "✓ Saved: $OUTPUT_DIR/03-function-response.json"

# 4. Tool Use Simulation (Anthropic style)
echo -e "\n4. Tool use (Anthropic style)..."
cat > "$OUTPUT_DIR/04-tool-request.json" << 'EOF'
{
  "model": "llama3.2:3b",
  "prompt": "Use the GitHub API to get repository topics. Format your response as: {\"tool_use\": {\"tool\": \"github_api\", \"params\": {\"endpoint\": \"/repos/{owner}/{repo}/topics\", \"method\": \"GET\"}}}",
  "stream": false
}
EOF

curl -s -X POST http://localhost:11434/api/generate \
  -H 'Content-Type: application/json' \
  -d @"$OUTPUT_DIR/04-tool-request.json" \
  | jq '.' > "$OUTPUT_DIR/04-tool-response.json"

echo "✓ Saved: $OUTPUT_DIR/04-tool-response.json"

# 5. Chat API Response
echo -e "\n5. Chat API response..."
cat > "$OUTPUT_DIR/05-chat-request.json" << 'EOF'
{
  "model": "llama3.2:3b",
  "messages": [
    {"role": "system", "content": "You are a helpful GitHub repository analyzer."},
    {"role": "user", "content": "What topics would you assign to a Scheme project?"}
  ],
  "stream": false
}
EOF

curl -s -X POST http://localhost:11434/api/chat \
  -H 'Content-Type: application/json' \
  -d @"$OUTPUT_DIR/05-chat-request.json" \
  | jq '.' > "$OUTPUT_DIR/05-chat-response.json"

echo "✓ Saved: $OUTPUT_DIR/05-chat-response.json"

# 6. Streaming Response (capture first few chunks)
echo -e "\n6. Streaming response chunks..."
cat > "$OUTPUT_DIR/06-stream-request.json" << 'EOF'
{
  "model": "llama3.2:3b",
  "prompt": "List three benefits of Scheme",
  "stream": true
}
EOF

curl -s -X POST http://localhost:11434/api/generate \
  -H 'Content-Type: application/json' \
  -d @"$OUTPUT_DIR/06-stream-request.json" \
  | head -10 > "$OUTPUT_DIR/06-stream-response.jsonl"

echo "✓ Saved: $OUTPUT_DIR/06-stream-response.jsonl"

# 7. Error Response (invalid model)
echo -e "\n7. Error response..."
cat > "$OUTPUT_DIR/07-error-request.json" << 'EOF'
{
  "model": "nonexistent:model",
  "prompt": "Test",
  "stream": false
}
EOF

curl -s -X POST http://localhost:11434/api/generate \
  -H 'Content-Type: application/json' \
  -d @"$OUTPUT_DIR/07-error-request.json" \
  > "$OUTPUT_DIR/07-error-response.json" 2>&1

echo "✓ Saved: $OUTPUT_DIR/07-error-response.json"

echo -e "\n=== Summary ==="
echo "All responses saved to: $OUTPUT_DIR/"
ls -la "$OUTPUT_DIR/"*.json*