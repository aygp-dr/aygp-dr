# Experiment 08: JSON Parsing in Scheme - Summary

## Experiment Complete ✓

### What We Learned
1. **Regex-based JSON parsing is fundamentally broken** - Even simple cases fail
2. **jq is a reliable solution** - Successfully parsed: `(scheme lisp functional-programming ollama github-api)`
3. **guile-json would be ideal** - But requires installation
4. **Proper parsing requires proper tools** - No shortcuts

### Working Solution
```scheme
(define (parse-topics-with-jq json-response)
  "Parse topics using jq command"
  (let* ((temp-file (string-append "/tmp/ollama-response-" 
                                  (number->string (getpid)) ".json")))
    ;; Write JSON to temp file
    (call-with-output-file temp-file
      (lambda (port)
        (display json-response port)))
    
    ;; Parse with jq
    (let* ((cmd (format #f "jq -r '.response | fromjson | .topics[]' < ~a 2>/dev/null" 
                        temp-file))
           (port (open-pipe* OPEN_READ "/bin/sh" "-c" cmd))
           (topics (let loop ((topics '()) (line (read-line port)))
                    (if (eof-object? line)
                        (reverse topics)
                        (loop (cons line topics) (read-line port))))))
      (close-pipe port)
      (delete-file temp-file)
      topics)))
```

### Next Steps
1. Update `repo-topics-simple` to use jq for JSON parsing
2. Add fallback for when jq is not available
3. Document the dependency on jq
4. Consider requiring guile-json for production use

### Files Created
- `FINDINGS.md` - Detailed analysis and observations
- `json-parser-proper.scm` - Working implementation
- `samples/*.json` - Test data from Ollama
- `custom-json-parser.scm` - Failed regex approach (educational)
- Various test files showing different approaches

### Key Takeaway
**Use the right tool for the job.** JSON has a grammar; use a JSON parser.