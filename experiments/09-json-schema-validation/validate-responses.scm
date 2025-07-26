#!/usr/bin/env guile
!#
;;; validate-responses.scm - Validate Ollama responses against schemas

(use-modules (ice-9 format)
             (ice-9 popen)
             (ice-9 rdelim)
             (srfi srfi-1))

(format #t "=== JSON Schema Validation for Ollama Responses ===~%~%")

;;; Validation Option 1: Using jq for basic validation
(define (validate-with-jq json-file checks)
  "Validate JSON using jq expressions"
  (format #t "Validating ~a with jq...~%" json-file)
  (for-each
   (lambda (check)
     (let* ((desc (car check))
            (jq-expr (cdr check))
            (cmd (format #f "jq '~a' ~a 2>&1" jq-expr json-file))
            (port (open-pipe* OPEN_READ "/bin/sh" "-c" cmd))
            (result (read-line port)))
       (close-pipe port)
       (format #t "  ~a: ~a~%" desc 
               (if (eof-object? result) "FAIL" "PASS"))))
   checks)
  (newline))

;;; Validation Option 2: Custom Scheme validators
(define (validate-structure data required-fields)
  "Check if data has required fields"
  (let ((missing (filter (lambda (field)
                          (not (assoc field data)))
                        required-fields)))
    (if (null? missing)
        '(pass . "All required fields present")
        `(fail . ,(format #f "Missing fields: ~a" missing)))))

(define (validate-type field-name value expected-type)
  "Validate field type"
  (let ((actual-type (cond
                      ((string? value) 'string)
                      ((number? value) 'number)
                      ((boolean? value) 'boolean)
                      ((list? value) 'array)
                      ((pair? value) 'object)
                      (else 'unknown))))
    (if (eq? actual-type expected-type)
        `(pass . ,(format #f "~a is ~a" field-name expected-type))
        `(fail . ,(format #f "~a should be ~a, got ~a" 
                         field-name expected-type actual-type)))))

(define (validate-pattern field-name value pattern)
  "Validate string against regex pattern"
  (if (and (string? value)
           (string-match pattern value))
      `(pass . ,(format #f "~a matches pattern" field-name))
      `(fail . ,(format #f "~a doesn't match pattern: ~a" field-name pattern))))

;;; Test cases for different response types

;; 1. Generate Response Validation
(format #t "1. Generate Response Validation~%")
(define generate-checks
  '(("Has model field" . ".model")
    ("Has response field" . ".response")
    ("Has done field" . ".done")
    ("Done is boolean" . "if .done | type == \"boolean\" then true else empty end")
    ("Response is string" . "if .response | type == \"string\" then true else empty end")
    ("Has created_at" . ".created_at")
    ("Model matches pattern" . "if .model | test(\"^[a-zA-Z0-9.-]+:[a-zA-Z0-9.-]+$\") then true else empty end")))

;; 2. Structured Topics Validation
(format #t "2. Topics Content Validation~%")
(define (validate-topics-content json-str)
  "Validate topics from structured output"
  (format #t "Validating topics content...~%")
  ;; First extract the response field
  (let* ((cmd (format #f "echo '~a' | jq -r '.response' 2>/dev/null" json-str))
         (port (open-pipe* OPEN_READ "/bin/sh" "-c" cmd))
         (response (read-line port)))
    (close-pipe port)
    (if (eof-object? response)
        (format #t "  FAIL: No response field~%")
        (begin
          ;; Parse the inner JSON
          (let* ((topics-cmd (format #f "echo '~a' | jq -r '.topics[]' 2>/dev/null" response))
                 (topics-port (open-pipe* OPEN_READ "/bin/sh" "-c" topics-cmd))
                 (topics (let loop ((topics '()) (line (read-line topics-port)))
                          (if (eof-object? line)
                              (reverse topics)
                              (loop (cons line topics) (read-line topics-port))))))
            (close-pipe topics-port)
            
            (format #t "  Topics found: ~a~%" (length topics))
            (for-each
             (lambda (topic)
               (let ((valid? (and (string? topic)
                                 (> (string-length topic) 0)
                                 (<= (string-length topic) 50)
                                 (string-match "^[a-z0-9][a-z0-9-]*[a-z0-9]?$" topic))))
                 (format #t "    ~a: ~a~%" topic (if valid? "✓" "✗"))))
             topics)))))
  (newline))

;; 3. Function Call Validation
(format #t "3. Function Call Content Validation~%")
(define (validate-function-call json-str)
  "Validate function call format"
  (format #t "Validating function call...~%")
  (let* ((cmd "jq '.response | fromjson | .function_call' 2>/dev/null")
         (full-cmd (format #f "echo '~a' | ~a" json-str cmd))
         (port (open-pipe* OPEN_READ "/bin/sh" "-c" full-cmd))
         (result (read-line port)))
    (close-pipe port)
    (format #t "  Has function_call: ~a~%" 
            (if (eof-object? result) "✗" "✓")))
  
  ;; Check for tool_use alternative
  (let* ((cmd "jq '.response | fromjson | .tool_use' 2>/dev/null")
         (full-cmd (format #f "echo '~a' | ~a" json-str cmd))
         (port (open-pipe* OPEN_READ "/bin/sh" "-c" full-cmd))
         (result (read-line port)))
    (close-pipe port)
    (format #t "  Has tool_use: ~a~%" 
            (if (eof-object? result) "✗" "✓")))
  (newline))

;; 4. Chat Response Validation
(format #t "4. Chat Response Validation~%")
(define chat-checks
  '(("Has message field" . ".message")
    ("Message has role" . ".message.role")
    ("Message has content" . ".message.content")
    ("Role is valid" . "if .message.role | IN(\"system\", \"user\", \"assistant\") then true else empty end")))

;; 5. Streaming Validation
(format #t "5. Streaming Response Validation~%")
(define (validate-streaming-chunk line)
  "Validate a single streaming chunk"
  (let* ((cmd (format #f "echo '~a' | jq '.done' 2>/dev/null" line))
         (port (open-pipe* OPEN_READ "/bin/sh" "-c" cmd))
         (done (read-line port)))
    (close-pipe port)
    (not (eof-object? done))))

;;; Advanced validation with JSON Schema (if ajv is available)
(define (ajv-available?)
  "Check if ajv-cli is installed"
  (zero? (system* "which" "ajv")))

(format #t "=== Advanced Schema Validation ===~%")
(if (ajv-available?)
    (format #t "✓ ajv is available for full schema validation~%")
    (format #t "✗ ajv not found - install with: npm install -g ajv-cli~%"))

;;; Example validation function for production use
(define (validate-ollama-response response-type json-data)
  "Main validation function"
  (case response-type
    ((generate)
     (validate-with-jq json-data generate-checks))
    ((topics)
     (validate-topics-content json-data))
    ((function-call)
     (validate-function-call json-data))
    ((chat)
     (validate-with-jq json-data chat-checks))
    (else
     (format #t "Unknown response type: ~a~%" response-type))))

(format #t "~%=== Recommendations ===~%")
(format #t "1. Use jq for quick validation in development~%")
(format #t "2. Use ajv for comprehensive schema validation~%")
(format #t "3. Build custom validators for specific business rules~%")
(format #t "4. Always validate before parsing nested JSON~%")
(format #t "5. Fail gracefully with clear error messages~%")