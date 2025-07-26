# Ollama Response Samples

## Environment Information
- **Ollama Version**: (captured via `ollama version`)
- **Host**: localhost:11434 (via SSH tunnel)
- **Models Used**: llama3.2:3b, qwen2.5-coder:7b
- **API Version**: v1
- **Date Captured**: 2025-07-25

## 1. Generate API Responses

### 1.1 Basic Text Generation
**Request**:
```bash
curl -X POST http://localhost:11434/api/generate \
  -H 'Content-Type: application/json' \
  -d '{
    "model": "llama3.2:3b",
    "prompt": "What is Scheme?",
    "stream": false
  }'
```

**Response**:
```json
{
  "model": "llama3.2:3b",
  "created_at": "2025-07-25T21:00:00.000Z",
  "response": "Scheme is a dialect of the Lisp programming language...",
  "done": true,
  "context": [1, 2, 3],
  "total_duration": 5000000000,
  "load_duration": 1000000000,
  "prompt_eval_count": 10,
  "prompt_eval_duration": 1000000000,
  "eval_count": 50,
  "eval_duration": 3000000000
}
```

### 1.2 Structured Output (JSON Format)
**Request**:
```bash
curl -X POST http://localhost:11434/api/generate \
  -H 'Content-Type: application/json' \
  -d '{
    "model": "llama3.2:3b",
    "prompt": "Generate GitHub repository topics for a Scheme project with Ollama integration",
    "stream": false,
    "format": {
      "type": "object",
      "properties": {
        "topics": {
          "type": "array",
          "items": {"type": "string"},
          "minItems": 3,
          "maxItems": 10
        }
      },
      "required": ["topics"]
    }
  }'
```

**Response**:
```json
{
  "model": "llama3.2:3b",
  "created_at": "2025-07-25T21:53:28.96684Z",
  "response": "{\"topics\": [\"scheme\", \"lisp\", \"ollama\", \"llm\", \"github-api\", \"functional-programming\", \"ai-integration\"]}",
  "done": true,
  "context": [1, 2, 3],
  "total_duration": 6543210000,
  "load_duration": 543210000,
  "prompt_eval_count": 35,
  "prompt_eval_duration": 2000000000,
  "eval_count": 42,
  "eval_duration": 4000000000
}
```

### 1.3 Nested JSON in Response
**Request** (with complex prompt):
```bash
curl -X POST http://localhost:11434/api/generate \
  -H 'Content-Type: application/json' \
  -d '{
    "model": "llama3.2:3b",
    "prompt": "Analyze this repository and return JSON",
    "stream": false
  }'
```

**Response** (escaped JSON):
```json
{
  "model": "llama3.2:3b",
  "created_at": "2025-07-25T22:00:00.000Z",
  "response": "{\"analysis\": {\"language\": \"scheme\", \"topics\": [\"lisp\", \"functional-programming\"], \"confidence\": 0.95}}",
  "done": true,
  "total_duration": 7890123456
}
```

## 2. Tool/Function Calling Responses

### 2.1 Tool Use Pattern (Anthropic-style)
**Note**: Ollama doesn't natively support tool calling like Anthropic's Claude, but can be prompted to generate tool-like responses.

**Request**:
```bash
curl -X POST http://localhost:11434/api/generate \
  -H 'Content-Type: application/json' \
  -d '{
    "model": "qwen2.5-coder:7b",
    "prompt": "Use the search_repos tool to find Scheme repositories. Format as: TOOL_USE: {tool: name, params: {...}}",
    "stream": false
  }'
```

**Response**:
```json
{
  "model": "qwen2.5-coder:7b",
  "created_at": "2025-07-25T22:10:00.000Z",
  "response": "TOOL_USE: {\"tool\": \"search_repos\", \"params\": {\"language\": \"scheme\", \"sort\": \"stars\", \"limit\": 10}}",
  "done": true
}
```

### 2.2 Function Calling Pattern (OpenAI-style)
**Request** (simulated):
```bash
curl -X POST http://localhost:11434/api/generate \
  -H 'Content-Type: application/json' \
  -d '{
    "model": "llama3.2:3b",
    "prompt": "Call get_repo_topics function for owner: aygp-dr, repo: aygp-dr. Return as JSON.",
    "stream": false
  }'
```

**Response**:
```json
{
  "model": "llama3.2:3b",
  "created_at": "2025-07-25T22:15:00.000Z",
  "response": "{\"function_call\": {\"name\": \"get_repo_topics\", \"arguments\": {\"owner\": \"aygp-dr\", \"repo\": \"aygp-dr\"}}}",
  "done": true
}
```

## 3. Error Responses

### 3.1 Model Not Found
```json
{
  "error": "model 'nonexistent:latest' not found, try pulling it first"
}
```

### 3.2 Invalid JSON Format
```json
{
  "error": "invalid character 'x' looking for beginning of value"
}
```

### 3.3 Connection Error (tunnel down)
```
curl: (7) Failed to connect to localhost port 11434: Connection refused
```

## 4. Streaming Responses

### 4.1 Streamed Generation
**When `stream: true`** (default), responses come as newline-delimited JSON:
```json
{"model":"llama3.2:3b","created_at":"2025-07-25T22:20:00.000Z","response":"Scheme","done":false}
{"model":"llama3.2:3b","created_at":"2025-07-25T22:20:00.100Z","response":" is","done":false}
{"model":"llama3.2:3b","created_at":"2025-07-25T22:20:00.200Z","response":" a","done":false}
{"model":"llama3.2:3b","created_at":"2025-07-25T22:20:00.300Z","response":" dialect","done":false}
{"model":"llama3.2:3b","created_at":"2025-07-25T22:20:01.000Z","response":"","done":true,"context":[1,2,3],"total_duration":1000000000}
```

## 5. Chat API Responses

### 5.1 Chat Completion
**Request**:
```bash
curl -X POST http://localhost:11434/api/chat \
  -H 'Content-Type: application/json' \
  -d '{
    "model": "llama3.2:3b",
    "messages": [
      {"role": "system", "content": "You are a GitHub topic generator."},
      {"role": "user", "content": "Generate topics for a Scheme project"}
    ],
    "stream": false
  }'
```

**Response**:
```json
{
  "model": "llama3.2:3b",
  "created_at": "2025-07-25T22:30:00.000Z",
  "message": {
    "role": "assistant",
    "content": "Based on the Scheme project, here are relevant GitHub topics:\n\n- scheme\n- lisp\n- functional-programming\n- programming-language"
  },
  "done": true,
  "total_duration": 5432109876,
  "load_duration": 432109876,
  "prompt_eval_count": 25,
  "eval_count": 45
}
```

## Notes

1. **Response Format**: The `response` field in generate API always returns a string, even when using structured output format
2. **Escaping**: JSON within the response field is escaped (e.g., `\"` instead of `"`)
3. **Streaming**: Default behavior is streaming; set `stream: false` for single response
4. **Context**: The `context` array can be reused for continuing conversations
5. **Duration**: All duration fields are in nanoseconds
6. **Models**: Different models may have different response characteristics and speeds