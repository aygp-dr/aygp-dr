#!/usr/bin/env bash
# Complete experiment for testing Ollama structured output
# Includes health checks, model listing, unstructured and structured tests

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Ollama Structured Output Experiment ===${NC}"
echo -e "${BLUE}===========================================${NC}"
echo ""

# Create output directory
mkdir -p output

# 1. Health Check
echo -e "${YELLOW}Step 1: Health Check${NC}"
echo "--------------------"
if curl -s http://localhost:11434 >/dev/null 2>&1; then
    echo -e "${GREEN}✓ Ollama server is running${NC}"
else
    echo -e "${RED}✗ Ollama server is not running${NC}"
    echo "Please start Ollama with: ollama serve"
    exit 1
fi
echo ""

# 2. List Available Models
echo -e "${YELLOW}Step 2: List Available Models${NC}"
echo "-----------------------------"
echo "Fetching model list..."
curl -s http://localhost:11434/api/tags | tee output/models-list.json | jq -r '.models[] | "\(.name) - \(.size | tostring | .[0:4])GB"' || {
    echo -e "${RED}Failed to list models${NC}"
    echo "Using fallback method..."
    ollama list 2>/dev/null || echo "No models available"
}
echo ""

# 3. Check if llama3.1 is available
echo -e "${YELLOW}Step 3: Check Model Availability${NC}"
echo "--------------------------------"
if curl -s http://localhost:11434/api/tags | jq -e '.models[] | select(.name | contains("llama3.1"))' >/dev/null 2>&1; then
    echo -e "${GREEN}✓ llama3.1 model is available${NC}"
    MODEL="llama3.1"
else
    echo -e "${YELLOW}⚠ llama3.1 not found, checking for alternatives...${NC}"
    # Try to find any llama model
    MODEL=$(curl -s http://localhost:11434/api/tags | jq -r '.models[0].name' 2>/dev/null || echo "")
    if [ -z "$MODEL" ]; then
        echo -e "${RED}✗ No models available. Please pull a model first:${NC}"
        echo "   ollama pull llama3.1"
        exit 1
    fi
    echo -e "${GREEN}Using model: $MODEL${NC}"
fi
echo ""

# 4. Simple Unstructured Generation Test
echo -e "${YELLOW}Step 4: Unstructured Generation Test${NC}"
echo "------------------------------------"
echo "Testing basic generation..."

curl -X POST http://localhost:11434/api/generate \
  -H "Content-Type: application/json" \
  -d "{
    \"model\": \"$MODEL\",
    \"prompt\": \"List 3 benefits of using Scheme for system programming in one sentence each.\",
    \"stream\": false
  }" \
  -s | tee output/test-unstructured.json | jq -r '.response' || echo -e "${RED}Failed to generate response${NC}"

echo ""
echo ""

# 5. Structured Output Test - Simple
echo -e "${YELLOW}Step 5: Simple Structured Output Test${NC}"
echo "-------------------------------------"
echo "Testing structured JSON output..."

curl -X POST http://localhost:11434/api/chat \
  -H "Content-Type: application/json" \
  -d "{
    \"model\": \"$MODEL\",
    \"messages\": [{\"role\": \"user\", \"content\": \"List 3 programming languages and their main use cases.\"}],
    \"stream\": false,
    \"format\": {
      \"type\": \"object\",
      \"properties\": {
        \"languages\": {
          \"type\": \"array\",
          \"items\": {
            \"type\": \"object\",
            \"properties\": {
              \"name\": {\"type\": \"string\"},
              \"use_case\": {\"type\": \"string\"}
            },
            \"required\": [\"name\", \"use_case\"]
          }
        }
      },
      \"required\": [\"languages\"]
    }
  }" \
  -s > output/test-structured-simple.json

if [ -f output/test-structured-simple.json ]; then
    echo "Response received. Parsing structured output..."
    cat output/test-structured-simple.json | jq -r '.message.content' | jq '.' 2>/dev/null || {
        echo -e "${YELLOW}Raw response:${NC}"
        cat output/test-structured-simple.json | jq '.'
    }
fi

echo ""
echo ""

# 6. Complex Structured Output Test (Original Lean4 example)
echo -e "${YELLOW}Step 6: Complex Structured Output Test${NC}"
echo "--------------------------------------"
echo "Testing complex structured output for Lean4..."

curl -X POST http://localhost:11434/api/chat \
  -H "Content-Type: application/json" \
  -d "{
    \"model\": \"$MODEL\",
    \"messages\": [{\"role\": \"user\", \"content\": \"List the main topics and features of the Lean4 programming language GitHub repository (leanprover/lean4). Include areas like theorem proving, functional programming features, and key components.\"}],
    \"stream\": false,
    \"format\": {
      \"type\": \"object\",
      \"properties\": {
        \"repository\": {
          \"type\": \"string\"
        },
        \"description\": {
          \"type\": \"string\"
        },
        \"main_topics\": {
          \"type\": \"array\",
          \"items\": {
            \"type\": \"string\"
          }
        },
        \"key_features\": {
          \"type\": \"array\",
          \"items\": {
            \"type\": \"string\"
          }
        },
        \"use_cases\": {
          \"type\": \"array\",
          \"items\": {
            \"type\": \"string\"
          }
        }
      },
      \"required\": [
        \"repository\",
        \"description\",
        \"main_topics\",
        \"key_features\",
        \"use_cases\"
      ]
    }
  }" \
  -s > output/test-structured-lean4.json

if [ -f output/test-structured-lean4.json ]; then
    echo "Response received. Parsing structured output..."
    cat output/test-structured-lean4.json | jq -r '.message.content' | jq '.' 2>/dev/null || {
        echo -e "${YELLOW}Raw response:${NC}"
        cat output/test-structured-lean4.json | jq '.'
    }
fi

echo ""
echo ""

# 7. Validate All Outputs
echo -e "${YELLOW}Step 7: Validation Summary${NC}"
echo "--------------------------"

for file in output/*.json; do
    if [ -f "$file" ]; then
        filename=$(basename "$file")
        echo -n "$filename: "
        
        # Check file size
        size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null || echo "0")
        if [ "$size" -eq 0 ]; then
            echo -e "${RED}✗ Empty file${NC}"
            continue
        fi
        
        # Check if valid JSON
        if jq -e . "$file" >/dev/null 2>&1; then
            echo -e "${GREEN}✓ Valid JSON${NC}"
            
            # For structured outputs, try to parse the content
            if [[ "$filename" == *"structured"* ]]; then
                if jq -e '.message.content' "$file" >/dev/null 2>&1; then
                    # Try to parse the content as JSON
                    if jq -r '.message.content' "$file" | jq -e . >/dev/null 2>&1; then
                        echo "  └─ ${GREEN}✓ Contains valid structured JSON content${NC}"
                        # Save parsed version
                        jq -r '.message.content' "$file" | jq '.' > "${file%.json}-parsed.json"
                    else
                        echo "  └─ ${YELLOW}⚠ Content is not valid JSON${NC}"
                    fi
                fi
            fi
        else
            echo -e "${RED}✗ Invalid JSON${NC}"
        fi
    fi
done

echo ""
echo -e "${BLUE}=== Experiment Complete ===${NC}"
echo "All outputs saved to ./output/"
echo ""
echo "Next steps:"
echo "1. Review the structured outputs to verify format compliance"
echo "2. Compare with the Scheme implementation in ../ollama-structured-scheme/"
echo "3. Use the validated formats for the repo metadata checker"