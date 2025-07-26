# Experiment 08: JSON Parsing in Scheme - Findings

## Key Finding
**Using regular expressions to parse JSON is fundamentally flawed and will lead to brittle code.**

Our tests demonstrate multiple failure modes:
- Can't handle escaped quotes properly
- Fails on nested structures
- Breaks with special characters
- No type safety or validation

## Better Alternatives

### 1. Install guile-json (Recommended)
```bash
# FreeBSD
pkg install guile-json

# Debian/Ubuntu
apt install guile-json

# Then use:
(use-modules (json))
(json-string->scm json-string)
```

### 2. Use jq via shell (Pragmatic)
```scheme
(define (parse-ollama-topics response)
  (let* ((cmd "jq -r '.response | fromjson | .topics[]' 2>/dev/null")
         (port (open-pipe* OPEN_READ "/bin/sh" "-c" 
                          (format #f "echo '~a' | ~a" response cmd)))
         (topics (let loop ((topics '()) (line (read-line port)))
                  (if (eof-object? line)
                      (reverse topics)
                      (loop (cons line topics) (read-line port))))))
    (close-pipe port)
    topics))
```

### 3. Modify Ollama Usage (Architectural Fix)
Instead of parsing complex JSON, use Ollama's chat API with simpler prompts:
```scheme
;; Ask for newline-separated topics instead of JSON
(define prompt "List GitHub topics for this repository, one per line, lowercase with hyphens:")
;; Then just split by newline
```

### 4. Write a Minimal JSON Parser (Educational)
If we must parse JSON without dependencies, write a proper recursive descent parser, not regex.

## Recommendation

1. **For production**: Install guile-json
2. **For this experiment**: Use jq if available, as it's commonly installed
3. **For the repo-topics tool**: Either:
   - Require guile-json as a dependency
   - Use jq and fail gracefully if not available
   - Change the Ollama prompt to return simpler format

## Lessons Learned

1. **Regex is not for parsing structured data** - JSON has a grammar that requires proper parsing
2. **Dependencies can be good** - guile-json exists for a reason
3. **API design matters** - If we control both ends, we can choose simpler formats
4. **Fail gracefully** - Provide clear error messages about missing dependencies

## Observations Report

### What We Tried
1. **Regex-based parsing** (`custom-json-parser.scm`) - Failed on:
   - Escaped quotes within JSON strings
   - Nested JSON structures
   - Array parsing with special characters
   - Even simple test cases produced incorrect results

2. **Manual string manipulation** - Fragile and incomplete

3. **Simple extraction patterns** - Only work for very specific formats

### Why It Failed
- JSON has a recursive grammar that regex cannot properly handle
- Escape sequences require stateful parsing
- Our regex patterns were capturing partial matches (e.g., `"{\\"` instead of full content)
- No way to validate structure or handle edge cases

### What Works
1. **Proper JSON libraries** (guile-json)
2. **External tools** (jq)
3. **Changing the problem** (simpler output format from Ollama)

## Updated Implementation

See `json-parser-proper.scm` for a working implementation using available tools.

## Experiment Artifacts
- `samples/` - Test JSON responses from Ollama
- `custom-json-parser.scm` - Regex approach (kept for educational purposes)
- `json-parser-proper.scm` - Recommended approaches
- `test-*.scm` - Various test cases showing failure modes