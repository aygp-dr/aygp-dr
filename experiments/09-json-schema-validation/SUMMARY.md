# Experiment 09: JSON Schema Validation - Summary

## Key Findings

### Validation Options Tested
1. **jq** - ✓ Works well for structure validation and field extraction
2. **ajv** - Not installed, but recommended for production
3. **Python jsonschema** - ✓ Available
4. **Custom Scheme validators** - ✓ Implemented successfully

### Working Solution
```scheme
;; Validate Ollama response
(validate-generate-response json-str)  ; ✓ Valid
(validate-topics-in-response json-str) ; ✓ Valid with proper topics
(validate-function-call-response json-str) ; ✓ Valid function calls
```

### Parsing Patterns for Llama 3.2

#### 1. Topics Extraction
```bash
# From structured output response
jq -r '.response | fromjson | .topics[]' response.json
```

#### 2. Function Call Parsing
```bash
# Extract function name and arguments
jq '.response | fromjson | .function_call' response.json
```

#### 3. Safe Nested JSON Parsing
```bash
# Handle escaped JSON in response field
jq '.response | try fromjson catch empty' response.json
```

## Validation Results

| Response Type | Required Fields | Type Checks | Pattern Validation | Result |
|--------------|----------------|-------------|-------------------|---------|
| Generate | model, response, done | ✓ | Model format | ✓ Pass |
| Topics | response with topics array | ✓ | GitHub topic rules | ✓ Pass |
| Function Call | response with function_call | ✓ | Name/arguments | ✓ Pass |
| Chat | message with role/content | ✓ | Valid roles | ✓ Pass |

## Invalid Topic Examples Caught
- `UPPERCASE` - Must be lowercase
- `spaces not allowed` - No spaces allowed
- `C++` - Special chars not allowed in topics

## Recommendations

1. **For Development**: Use jq for quick validation and parsing
2. **For Production**: Install ajv for comprehensive schema validation
3. **For Scheme Projects**: Use the provided validators with jq
4. **Error Handling**: Always validate before parsing nested JSON

## Integration with repo-topics Tool

```scheme
;; 1. Validate response structure
(let ((validation (validate-generate-response ollama-response)))
  (if (eq? (car validation) 'valid)
      ;; 2. Extract and validate topics
      (let ((topics (parse-topics-with-jq ollama-response)))
        ;; 3. Filter valid topics only
        (filter valid-github-topic? topics))
      ;; 4. Handle validation errors
      (error "Invalid response" (cdr validation))))
```

## Files Created
- `ollama-schemas.json` - JSON schemas for all response types
- `json-validator.scm` - Working validation implementation
- `parsing-examples.md` - Comprehensive parsing guide
- Test scripts and examples

## Next Steps
1. Update `repo-topics-simple` to use these validators
2. Add retry logic for validation failures
3. Consider caching validated responses
4. Document dependency on jq