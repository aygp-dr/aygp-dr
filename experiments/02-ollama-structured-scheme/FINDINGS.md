# Experiment 02 Findings: Ollama Structured Output in Scheme

## Date: 2025-07-25

### Key Learnings

1. **JSON Escaping Challenges**
   - Initial implementation had issues with shell escaping when passing JSON through curl
   - Single quotes in the curl command conflicted with Scheme's string handling
   - Solution: Need proper JSON escaping or use of temporary files

2. **Ollama Connectivity Edge Cases**
   - Ollama service can be intermittently unavailable through SSH tunnels
   - Connection drops require manual tunnel restarts
   - Basic connectivity test succeeds but structured requests may fail

3. **Guile Module Dependencies**
   - `string-match` requires `(ice-9 regex)` module
   - `match:substring` is provided by the regex module
   - Guile 2.2.7 has different module structure than newer versions

4. **Error Handling Observations**
   - Silent failures when JSON parsing fails
   - Need better error reporting for API responses
   - Scheme's error handling differs from bash's exit codes

### Technical Issues Encountered

1. **JSON Generation**
   ```scheme
   ;; Issue: Nested quotes in JSON strings
   (format #f "~s" data)  ; Produces Scheme-style quotes
   ;; Need: Proper JSON string escaping
   ```

2. **Shell Command Construction**
   ```scheme
   ;; Problem: Using single quotes in shell command
   (format #f "curl ... -d '~a'" json)
   ;; Better: Use stdin or temp file
   ```

3. **Response Parsing**
   - Raw curl output includes both response and potential errors
   - No distinction between network errors and API errors
   - Need structured error handling

### Recommendations for Improvement

1. **Use HTTP Library**
   - Consider using Guile's web client instead of curl
   - Avoids shell escaping issues
   - Better error handling

2. **JSON Library**
   - Import proper JSON library for Guile
   - Handles escaping automatically
   - Supports round-trip conversion

3. **Error Recovery**
   - Implement retry logic for transient failures
   - Better logging of request/response pairs
   - Separate network errors from API errors

### Successful Elements

1. **Basic Connectivity**: Simple POST requests work
2. **Module Structure**: Clean separation of concerns
3. **Test Framework**: Multiple test cases prepared
4. **ANSI Colors**: Good visual feedback

### Next Steps

1. Fix JSON escaping issues
2. Implement proper error handling
3. Add request/response logging
4. Consider alternative HTTP client approach

## Update: 2025-07-25 (Continued)

### Improvements Made

1. **Created ollama-structured-v2.scm**
   - Uses temporary files to avoid shell escaping
   - Proper JSON string escaping function
   - Better error handling with exit codes

2. **Added Makefile targets**
   - `make debug` - Test basic connectivity
   - `make run-v2` - Run improved version
   - Follows gmake -C pattern for consistency

3. **Successful Connection**
   - Basic Ollama API calls work
   - Response received (1021 characters)
   - JSON parsing still needs work

### Remaining Issues

1. **Content Extraction**
   - Regex pattern doesn't match Ollama's response format
   - Need to parse nested JSON structure
   - Consider using proper JSON parser

2. **Module Dependencies**
   - Need to add `(ice-9 match)` for pattern matching
   - Auto-compilation warnings can be suppressed

### Lessons Learned

1. **Always use `gmake -C`** instead of cd && make
2. **Temporary files** solve shell escaping issues
3. **Debug targets** are essential for troubleshooting
4. **Ollama response format** varies by model and request type