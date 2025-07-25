#!/usr/bin/env bash
# Baseline test for Ollama structured output using curl

set -e

echo "=== Ollama Structured Output Experiment ==="
echo "Testing structured JSON output format with Ollama API"
echo "==========================================="
echo ""

# Check if Ollama is running
if ! curl -s http://localhost:11434/api/tags >/dev/null 2>&1; then
    echo "Error: Ollama is not running on localhost:11434"
    echo "Please start Ollama with: ollama serve"
    exit 1
fi

# Create output directory
mkdir -p output

# Test 1: Basic structured output for Lean4 repository
echo "Test 1: Requesting structured output for Lean4 repository..."
echo "------------------------------------------------------------"

curl -X POST http://localhost:11434/api/chat \
  -H "Content-Type: application/json" \
  -d '{
    "model": "llama3.1",
    "messages": [{"role": "user", "content": "List the main topics and features of the Lean4 programming language GitHub repository (leanprover/lean4). Include areas like theorem proving, functional programming features, and key components."}],
    "stream": false,
    "format": {
      "type": "object",
      "properties": {
        "repository": {
          "type": "string"
        },
        "description": {
          "type": "string"
        },
        "main_topics": {
          "type": "array",
          "items": {
            "type": "string"
          }
        },
        "key_features": {
          "type": "array",
          "items": {
            "type": "string"
          }
        },
        "use_cases": {
          "type": "array",
          "items": {
            "type": "string"
          }
        }
      },
      "required": [
        "repository",
        "description",
        "main_topics",
        "key_features",
        "use_cases"
      ]
    }
  }' \
  -s | tee output/test1-lean4.json | jq '.'

echo ""
echo "Test 2: GitHub repository metadata suggestion format..."
echo "-------------------------------------------------------"

# Test 2: Repository metadata suggestions
curl -X POST http://localhost:11434/api/chat \
  -H "Content-Type: application/json" \
  -d '{
    "model": "llama3.1",
    "messages": [{"role": "user", "content": "Suggest GitHub repository metadata (description and topics) for a Scheme implementation of a GitHub repository metadata checker that uses the GitHub API."}],
    "stream": false,
    "format": {
      "type": "object",
      "properties": {
        "suggested_description": {
          "type": "string",
          "maxLength": 350
        },
        "suggested_topics": {
          "type": "array",
          "items": {
            "type": "string",
            "pattern": "^[a-z0-9-]+$"
          },
          "minItems": 3,
          "maxItems": 20
        },
        "rationale": {
          "type": "string"
        }
      },
      "required": [
        "suggested_description",
        "suggested_topics",
        "rationale"
      ]
    }
  }' \
  -s | tee output/test2-metadata.json | jq '.'

echo ""
echo "Test 3: Complex nested structure..."
echo "-----------------------------------"

# Test 3: More complex nested structure
curl -X POST http://localhost:11434/api/chat \
  -H "Content-Type: application/json" \
  -d '{
    "model": "llama3.1",
    "messages": [{"role": "user", "content": "Analyze the GitHub API endpoints for repository management and categorize them by operation type."}],
    "stream": false,
    "format": {
      "type": "object",
      "properties": {
        "api_analysis": {
          "type": "object",
          "properties": {
            "read_operations": {
              "type": "array",
              "items": {
                "type": "object",
                "properties": {
                  "endpoint": {"type": "string"},
                  "description": {"type": "string"},
                  "http_method": {"type": "string"}
                }
              }
            },
            "write_operations": {
              "type": "array",
              "items": {
                "type": "object",
                "properties": {
                  "endpoint": {"type": "string"},
                  "description": {"type": "string"},
                  "http_method": {"type": "string"}
                }
              }
            },
            "authentication_required": {
              "type": "boolean"
            }
          }
        }
      },
      "required": ["api_analysis"]
    }
  }' \
  -s | tee output/test3-api-analysis.json | jq '.'

echo ""
echo "=== Summary ==="
echo "All test outputs saved to ./output/"
echo ""

# Validate the outputs
echo "Validating outputs..."
for file in output/*.json; do
    if [ -f "$file" ]; then
        echo -n "$(basename "$file"): "
        if jq -e '.message.content | fromjson' "$file" >/dev/null 2>&1; then
            echo "✓ Valid structured JSON response"
            # Extract and pretty print the content
            jq -r '.message.content | fromjson' "$file" > "${file%.json}-parsed.json"
        else
            echo "✗ Invalid or missing structured content"
        fi
    fi
done

echo ""
echo "Experiment complete!"