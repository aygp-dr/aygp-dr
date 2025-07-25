# Experiment 04 Findings: GitHub API Integration

## Date: 2025-07-25

### Key Learnings

1. **Guile Syntax Differences**
   - Keyword arguments require `define*` instead of `define`
   - `#:key` syntax for optional parameters
   - Need to explicitly import helper modules

2. **API Response Parsing**
   - Rate limit headers have unexpected values (limit: 5, remaining: 7994)
   - This suggests header parsing issues or API changes
   - Link header parsing reverses the rel values ("last" becomes "tsal")

3. **Missing Standard Functions**
   - Guile doesn't have built-in `string-trim`, `string-index`, etc.
   - Need to implement these utility functions
   - `assoc-ref` is not standard, must be defined

4. **Module Loading**
   - `(load "file.scm")` works for local file inclusion
   - Auto-compilation warnings can be suppressed
   - Module dependencies must be explicit

### Technical Issues Encountered

1. **Header Parsing**
   ```scheme
   ;; Issue: Rate limit values are incorrect
   ((limit . 5) (remaining . 7994) (reset . 7876643571))
   ;; Expected: limit around 5000, remaining < limit
   ```

2. **String Reversal in Parsing**
   ```scheme
   ;; Link relations are reversed
   ((tsal . ...) (txen . ...))  ; Should be "last" and "next"
   ```

3. **JSON Response Handling**
   - No actual JSON parsing implemented
   - Only detects if response starts with `[` or `{`
   - Need proper JSON library for real use

### Successful Elements

1. **Authentication Works**: Bearer token properly included
2. **Basic Requests Succeed**: Can fetch user and repos
3. **Pagination Headers Detected**: Link headers are found
4. **Rate Limit Headers Present**: Headers exist in response

### Recommendations

1. **Fix String Processing**
   - Debug the string reversal issue in parsing
   - Implement proper header value extraction

2. **Add JSON Library**
   - Use `guile-json` package for proper parsing
   - Or implement minimal JSON parser

3. **Error Handling**
   - Add HTTP status code checking
   - Handle network errors gracefully

4. **Testing Strategy**
   - Mock responses for consistent testing
   - Add unit tests for parsing functions

### Next Steps

1. Debug header parsing logic
2. Fix string reversal issues
3. Implement proper JSON response handling
4. Add comprehensive error handling
5. Create integration tests with real API