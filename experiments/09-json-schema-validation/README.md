# Experiment 09: JSON Schema Validation for Ollama Responses

## Objective
Explore options for validating JSON responses from Ollama against schemas to handle unexpected responses gracefully.

## JSON Schema Validation Options

### 1. **jq with Schema Validation**
```bash
# Basic structure validation
jq 'if .response and .model and .done then . else error("Invalid structure") end'

# Type checking
jq 'if (.response | type) == "string" then . else error("response must be string") end'
```

### 2. **JSON Schema Tools**
- **ajv** (JavaScript) - Fast JSON Schema validator
- **jsonschema** (Python) - Standard Python implementation
- **json-schema** (Ruby) - Ruby implementation
- **gojsonschema** (Go) - Go implementation

### 3. **Guile/Scheme Options**
- **guile-json** with manual validation
- **SRFI-180** (if available) with custom validators
- Shell out to validation tools

### 4. **Custom Validation in Scheme**
Build type checkers and structure validators

## Ollama Response Types to Validate

### 1. Generate API Response
Basic text generation with metadata

### 2. Structured Output Response
JSON formatted response field

### 3. Function Calling Response
Tool/function invocation format (simulated)

### 4. Chat API Response
Conversation format with roles

### 5. Streaming Response
Multiple JSON objects per response

## Success Criteria
- Detect malformed JSON early
- Validate required fields exist
- Check data types match expected
- Handle edge cases gracefully
- Provide clear error messages