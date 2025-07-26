#!/usr/bin/env guile
!#
;;; json-validator.scm - Practical JSON validation for Ollama responses

(use-modules (ice-9 format)
             (ice-9 popen)
             (ice-9 rdelim)
             (ice-9 regex)
             (srfi srfi-1))

;;; Helper functions
(define (read-string port)
  "Read entire port as string"
  (let loop ((chars '()) (ch (read-char port)))
    (if (eof-object? ch)
        (list->string (reverse chars))
        (loop (cons ch chars) (read-char port)))))

(define (string-contains haystack needle)
  "Check if string contains substring"
  (if (string-match needle haystack) #t #f))

;;; Core validation functions

(define (validate-json-structure json-str)
  "Basic JSON structure validation"
  (let* ((temp-file (format #f "/tmp/json-validate-~a.json" (getpid))))
    (call-with-output-file temp-file
      (lambda (port) (display json-str port)))
    (let* ((cmd (format #f "jq '.' < ~a 2>&1" temp-file))
           (port (open-pipe* OPEN_READ "/bin/sh" "-c" cmd))
           (result (read-string port)))
      (close-pipe port)
      (delete-file temp-file)
      (not (string-contains result "parse error")))))

(define (extract-field json-str field-path)
  "Extract field value using jq"
  (let* ((temp-file (format #f "/tmp/json-validate-~a.json" (getpid))))
    ;; Write JSON to temp file
    (call-with-output-file temp-file
      (lambda (port) (display json-str port)))
    ;; Extract with jq
    (let* ((cmd (format #f "jq -r '~a' < ~a 2>/dev/null" field-path temp-file))
           (port (open-pipe* OPEN_READ "/bin/sh" "-c" cmd))
           (result (read-line port)))
      (close-pipe port)
      (delete-file temp-file)
      (if (or (eof-object? result) (string=? result "null"))
          #f
          result))))

(define (check-field-exists json-str field-path)
  "Check if field exists in JSON"
  (let ((value (extract-field json-str field-path)))
    (and value (not (string=? value "null")))))

(define (check-field-type json-str field-path expected-type)
  "Check field type"
  (let* ((temp-file (format #f "/tmp/json-validate-~a.json" (getpid))))
    (call-with-output-file temp-file
      (lambda (port) (display json-str port)))
    (let* ((cmd (format #f "jq -r '~a | type' < ~a 2>/dev/null" field-path temp-file))
           (port (open-pipe* OPEN_READ "/bin/sh" "-c" cmd))
           (result (read-line port)))
      (close-pipe port)
      (delete-file temp-file)
      (and (not (eof-object? result))
           (string=? result expected-type)))))

;;; Ollama-specific validators

(define (validate-generate-response json-str)
  "Validate standard generate API response"
  (let ((errors '()))
    ;; Check required fields
    (for-each
     (lambda (field)
       (unless (check-field-exists json-str (format #f ".~a" field))
         (set! errors (cons (format #f "Missing required field: ~a" field) errors))))
     '("model" "created_at" "response" "done"))
    
    ;; Check types
    (when (check-field-exists json-str ".response")
      (unless (check-field-type json-str ".response" "string")
        (set! errors (cons "response must be string" errors))))
    
    (when (check-field-exists json-str ".done")
      (unless (check-field-type json-str ".done" "boolean")
        (set! errors (cons "done must be boolean" errors))))
    
    ;; Check model format
    (let ((model (extract-field json-str ".model")))
      (when (and model (not (string-match "^[a-zA-Z0-9.-]+:[a-zA-Z0-9.-]+$" model)))
        (set! errors (cons "Invalid model format" errors))))
    
    (if (null? errors)
        '(valid . "Generate response is valid")
        `(invalid . ,errors))))

(define (validate-topics-in-response json-str)
  "Validate topics within response field"
  (let ((response-field (extract-field json-str ".response")))
    (if response-field
        (validate-topics-array response-field)
        '(invalid . ("No response field found")))))

(define (validate-topics-array json-str)
  "Validate topics array structure and content"
  (let ((errors '()))
    ;; Check if it's valid JSON
    (unless (validate-json-structure json-str)
      (set! errors (cons "Response field contains invalid JSON" errors)))
    
    ;; Check for topics array
    (unless (check-field-exists json-str ".topics")
      (set! errors (cons "No topics array found" errors)))
    
    (when (check-field-exists json-str ".topics")
      (unless (check-field-type json-str ".topics" "array")
        (set! errors (cons "topics must be an array" errors)))
      
      ;; Extract and validate individual topics
      (let* ((temp-file (format #f "/tmp/json-topics-~a.json" (getpid))))
        (call-with-output-file temp-file
          (lambda (port) (display json-str port)))
        (let* ((cmd (format #f "jq -r '.topics[]' < ~a 2>/dev/null" temp-file))
               (port (open-pipe* OPEN_READ "/bin/sh" "-c" cmd))
               (topics (let loop ((topics '()) (line (read-line port)))
                        (if (eof-object? line)
                            (reverse topics)
                            (loop (cons line topics) (read-line port))))))
          (close-pipe port)
          (delete-file temp-file)
          ;; Validate each topic
          (for-each
           (lambda (topic)
             (unless (valid-github-topic? topic)
               (set! errors (cons (format #f "Invalid topic: ~a" topic) errors))))
           topics))))
    
    (if (null? errors)
        '(valid . "Topics are valid")
        `(invalid . ,errors))))

(define (valid-github-topic? topic)
  "Check if topic meets GitHub requirements"
  (and (string? topic)
       (> (string-length topic) 0)
       (<= (string-length topic) 50)
       (string-match "^[a-z0-9][a-z0-9-]*[a-z0-9]?$" topic)))

(define (validate-function-call-response json-str)
  "Validate function calling format in response"
  (let ((response-field (extract-field json-str ".response")))
    (if response-field
        (let ((errors '()))
          ;; Check for function_call or tool_use
          (let ((has-function-call (check-field-exists response-field ".function_call"))
                (has-tool-use (check-field-exists response-field ".tool_use")))
            (unless (or has-function-call has-tool-use)
              (set! errors (cons "No function_call or tool_use found" errors)))
            
            (when has-function-call
              (unless (check-field-exists response-field ".function_call.name")
                (set! errors (cons "function_call missing name" errors)))
              (unless (check-field-exists response-field ".function_call.arguments")
                (set! errors (cons "function_call missing arguments" errors))))
            
            (when has-tool-use
              (unless (check-field-exists response-field ".tool_use.tool")
                (set! errors (cons "tool_use missing tool" errors)))
              (unless (check-field-exists response-field ".tool_use.params")
                (set! errors (cons "tool_use missing params" errors)))))
          
          (if (null? errors)
              '(valid . "Function call is valid")
              `(invalid . ,errors)))
        '(invalid . ("No response field found")))))

(define (validate-chat-response json-str)
  "Validate chat API response"
  (let ((errors '()))
    ;; Check required fields
    (for-each
     (lambda (field)
       (unless (check-field-exists json-str (format #f ".~a" field))
         (set! errors (cons (format #f "Missing required field: ~a" field) errors))))
     '("model" "created_at" "message" "done"))
    
    ;; Check message structure
    (when (check-field-exists json-str ".message")
      (unless (check-field-exists json-str ".message.role")
        (set! errors (cons "message missing role" errors)))
      (unless (check-field-exists json-str ".message.content")
        (set! errors (cons "message missing content" errors)))
      
      ;; Validate role
      (let ((role (extract-field json-str ".message.role")))
        (when (and role (not (member role '("system" "user" "assistant"))))
          (set! errors (cons (format #f "Invalid role: ~a" role) errors)))))
    
    (if (null? errors)
        '(valid . "Chat response is valid")
        `(invalid . ,errors))))

;;; Main validation dispatcher

(define (validate-ollama-response response-type json-str)
  "Validate Ollama response based on type"
  (if (not (validate-json-structure json-str))
      '(invalid . ("Invalid JSON structure"))
      (case response-type
        ((generate) (validate-generate-response json-str))
        ((topics) (validate-topics-in-response json-str))
        ((function-call) (validate-function-call-response json-str))
        ((chat) (validate-chat-response json-str))
        (else '(invalid . ("Unknown response type"))))))

;;; Pretty print validation results

(define (print-validation-result result)
  "Print validation result nicely"
  (let ((status (car result))
        (details (cdr result)))
    (if (eq? status 'valid)
        (format #t "✓ ~a~%" details)
        (begin
          (format #t "✗ Validation failed:~%")
          (for-each (lambda (error)
                     (format #t "  - ~a~%" error))
                   details)))))

;;; Test with examples

(format #t "=== Ollama Response Validation Examples ===~%~%")

;; Example 1: Valid generate response
(format #t "1. Generate Response:~%")
(define example-generate
  "{\"model\":\"llama3.2:3b\",\"created_at\":\"2025-07-25T21:00:00Z\",\"response\":\"Functional programming is a paradigm...\",\"done\":true}")
(print-validation-result (validate-generate-response example-generate))
(newline)

;; Example 2: Topics response
(format #t "2. Topics Response:~%")
(define example-topics
  "{\"model\":\"llama3.2:3b\",\"created_at\":\"2025-07-25T21:00:00Z\",\"response\":\"{\\\"topics\\\": [\\\"scheme\\\", \\\"lisp\\\", \\\"functional-programming\\\", \\\"ollama\\\", \\\"github-api\\\"]}\",\"done\":true}")
(print-validation-result (validate-topics-in-response example-topics))
(newline)

;; Example 3: Invalid topics
(format #t "3. Invalid Topics:~%")
(define example-bad-topics
  "{\"model\":\"llama3.2:3b\",\"created_at\":\"2025-07-25T21:00:00Z\",\"response\":\"{\\\"topics\\\": [\\\"UPPERCASE\\\", \\\"spaces not allowed\\\", \\\"C++\\\"]}\",\"done\":true}")
(print-validation-result (validate-topics-in-response example-bad-topics))
(newline)

;; Example 4: Function call
(format #t "4. Function Call:~%")
(define example-function
  "{\"model\":\"llama3.2:3b\",\"created_at\":\"2025-07-25T21:00:00Z\",\"response\":\"{\\\"function_call\\\": {\\\"name\\\": \\\"search_repos\\\", \\\"arguments\\\": {\\\"language\\\": \\\"scheme\\\"}}}\",\"done\":true}")
(print-validation-result (validate-function-call-response example-function))

(format #t "~%=== Usage in repo-topics tool ===~%")
(format #t "1. Always validate structure before parsing~%")
(format #t "2. Check response type and apply appropriate validator~%")
(format #t "3. Provide clear errors to user~%")
(format #t "4. Consider retrying with different prompts on validation failure~%")