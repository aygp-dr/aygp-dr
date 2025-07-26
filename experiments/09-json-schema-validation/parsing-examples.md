# Ollama Response Parsing Examples with Llama 3.2

## 1. Basic Generate Response

### Request
```json
{
  "model": "llama3.2:3b",
  "prompt": "What is functional programming?",
  "stream": false
}
```

### Response
```json
{
  "model": "llama3.2:3b",
  "created_at": "2025-07-25T21:00:00.000Z",
  "response": "Functional programming is a programming paradigm that treats computation as the evaluation of mathematical functions...",
  "done": true,
  "context": [1, 2, 3],
  "total_duration": 5000000000,
  "load_duration": 1000000000,
  "eval_count": 150
}
```

### Parsing with jq
```bash
# Extract response text
jq -r '.response' response.json

# Check if done
jq '.done' response.json

# Get timing info
jq '{duration: (.total_duration / 1000000000), tokens: .eval_count}' response.json
```

### Validation
```scheme
(validate-generate-response json-str)
; Checks: model, created_at, response, done fields exist and have correct types
```

## 2. Structured Output (Topics)

### Request
```json
{
  "model": "llama3.2:3b",
  "prompt": "Generate GitHub topics for a Scheme project with Ollama integration",
  "stream": false,
  "format": {
    "type": "object",
    "properties": {
      "topics": {
        "type": "array",
        "items": {"type": "string"}
      }
    }
  }
}
```

### Response
```json
{
  "model": "llama3.2:3b",
  "created_at": "2025-07-25T21:53:28.96684Z",
  "response": "{\"topics\": [\"scheme\", \"lisp\", \"functional-programming\", \"ollama\", \"github-api\"]}",
  "done": true
}
```

### Parsing with jq
```bash
# Extract topics array
jq -r '.response | fromjson | .topics[]' response.json

# Output:
# scheme
# lisp
# functional-programming
# ollama
# github-api

# Get as JSON array
jq '.response | fromjson | .topics' response.json
# ["scheme", "lisp", "functional-programming", "ollama", "github-api"]

# Validate each topic
jq -r '.response | fromjson | .topics[] | 
  if test("^[a-z0-9][a-z0-9-]*[a-z0-9]?$") and (length <= 50) 
  then "\(.) ✓" 
  else "\(.) ✗" end' response.json
```

### Scheme Implementation
```scheme
(define (parse-topics-response json-str)
  (let* ((response-field (extract-field json-str ".response"))
         (topics-cmd (format #f "echo '~a' | jq -r '.topics[]'" response-field))
         (port (open-pipe* OPEN_READ "/bin/sh" "-c" topics-cmd))
         (topics (read-all-lines port)))
    (close-pipe port)
    (filter valid-github-topic? topics)))
```

## 3. Function Call Response (OpenAI Style)

### Request
```json
{
  "model": "llama3.2:3b",
  "prompt": "Call search_repositories with language='scheme', sort='stars'",
  "stream": false
}
```

### Response
```json
{
  "model": "llama3.2:3b",
  "created_at": "2025-07-25T22:00:00.000Z",
  "response": "{\"function_call\": {\"name\": \"search_repositories\", \"arguments\": {\"language\": \"scheme\", \"sort\": \"stars\", \"limit\": 10}}}",
  "done": true
}
```

### Parsing with jq
```bash
# Extract function name
jq -r '.response | fromjson | .function_call.name' response.json

# Extract arguments
jq '.response | fromjson | .function_call.arguments' response.json

# Get specific argument
jq -r '.response | fromjson | .function_call.arguments.language' response.json
```

## 4. Tool Use Response (Anthropic Style)

### Request
```json
{
  "model": "llama3.2:3b",
  "prompt": "Use the github_api tool to get repository topics",
  "stream": false
}
```

### Response
```json
{
  "model": "llama3.2:3b",
  "created_at": "2025-07-25T22:05:00.000Z",
  "response": "{\"tool_use\": {\"tool\": \"github_api\", \"params\": {\"endpoint\": \"/repos/{owner}/{repo}/topics\", \"method\": \"GET\"}}}",
  "done": true
}
```

### Parsing with jq
```bash
# Extract tool name
jq -r '.response | fromjson | .tool_use.tool' response.json

# Extract parameters
jq '.response | fromjson | .tool_use.params' response.json
```

## 5. Chat API Response

### Request
```json
{
  "model": "llama3.2:3b",
  "messages": [
    {"role": "system", "content": "You are a GitHub topic generator"},
    {"role": "user", "content": "Generate topics for a Scheme project"}
  ],
  "stream": false
}
```

### Response
```json
{
  "model": "llama3.2:3b",
  "created_at": "2025-07-25T22:10:00.000Z",
  "message": {
    "role": "assistant",
    "content": "For a Scheme project, I suggest these topics:\n- scheme\n- lisp\n- functional-programming"
  },
  "done": true
}
```

### Parsing with jq
```bash
# Extract message content
jq -r '.message.content' response.json

# Extract role
jq -r '.message.role' response.json

# Parse topics from content (if formatted as list)
jq -r '.message.content | split("\n") | .[] | select(startswith("- ")) | ltrimstr("- ")' response.json
```

## 6. Streaming Response

### When stream: true (default)
```jsonl
{"model":"llama3.2:3b","created_at":"2025-07-25T22:20:00.000Z","response":"Here","done":false}
{"model":"llama3.2:3b","created_at":"2025-07-25T22:20:00.100Z","response":" are","done":false}
{"model":"llama3.2:3b","created_at":"2025-07-25T22:20:00.200Z","response":" the","done":false}
{"model":"llama3.2:3b","created_at":"2025-07-25T22:20:00.300Z","response":" topics:","done":false}
{"model":"llama3.2:3b","created_at":"2025-07-25T22:20:01.000Z","response":"","done":true,"context":[1,2,3],"total_duration":1000000000}
```

### Parsing streaming responses
```bash
# Process each line
while IFS= read -r line; do
  echo "$line" | jq -r 'if .done then "DONE" else .response end'
done < stream.jsonl

# Concatenate all responses
jq -r 'select(.response) | .response' stream.jsonl | tr -d '\n'
```

## Error Handling

### Model not found
```json
{"error": "model 'nonexistent:latest' not found, try pulling it first"}
```

### Invalid JSON in prompt
```json
{"error": "invalid character 'x' looking for beginning of value"}
```

### Parsing errors
```bash
# Check for error field
jq 'if .error then "ERROR: \(.error)" else "OK" end' response.json

# Validate before parsing nested JSON
jq 'if .response then (.response | fromjson) else empty end' response.json
```

## Best Practices

1. **Always validate structure first**
   ```bash
   jq 'has("response") and has("done")' response.json
   ```

2. **Handle nested JSON safely**
   ```bash
   jq '.response | try fromjson catch empty' response.json
   ```

3. **Check types before parsing**
   ```bash
   jq 'if (.response | type) == "string" then .response else empty end' response.json
   ```

4. **Use schemas for validation**
   ```bash
   # With ajv-cli
   ajv validate -s schema.json -d response.json
   ```

5. **Fail gracefully**
   ```scheme
   (catch #t
     (lambda () (parse-topics json-str))
     (lambda (key . args) 
       (format #t "Failed to parse: ~a~%" args)
       '()))