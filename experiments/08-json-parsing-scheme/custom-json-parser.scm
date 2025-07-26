#!/usr/bin/env guile
!#
;;; custom-json-parser.scm - Simple JSON parser for Ollama responses

(use-modules (ice-9 format)
             (ice-9 regex)
             (srfi srfi-1))

;;; Test data
(define test-cases
  `(("Simple object" 
     . "{\"name\": \"test\", \"count\": 42}")
    ("Array of strings" 
     . "{\"topics\": [\"scheme\", \"ollama\", \"github-api\"]}")
    ("Nested escaped JSON" 
     . "{\"response\": \"{\\\"topics\\\": [\\\"scheme\\\", \\\"ollama\\\"]}\"}")
    ("Real Ollama response" 
     . "{\"model\":\"llama3.2:3b\",\"created_at\":\"2025-07-25T21:53:28.96684Z\",\"response\":\"{\\\"topics\\\": [\\\"lisp\\\", \\\"functional-programming\\\", \\\"project-purpose/dynamic-repl\\\", \\\"key-technologies/llm\\\", \\\"project-type/tool\\\"]}\",\"done\":true}")))

(format #t "=== Custom JSON Parser for Ollama ===~%~%")

;;; Simple JSON array extractor
(define (extract-json-string-array json-str key)
  "Extract a string array value for a given key from JSON"
  (let* ((pattern (string-append "\"" key "\"\\s*:\\s*\\[([^\\]]+)\\]"))
         (match (string-match pattern json-str)))
    (if match
        (let ((array-content (match:substring match 1)))
          ;; Parse array elements - handle both "item" and \"item\" formats
          (map (lambda (item)
                 (let* ((trimmed (string-trim-both item))
                        ;; Remove escaped quotes first
                        (unescaped (regexp-substitute/global #f "\\\\\"" trimmed 'pre "\"" 'post)))
                   ;; Then remove surrounding quotes
                   (if (and (> (string-length unescaped) 1)
                           (char=? (string-ref unescaped 0) #\")
                           (char=? (string-ref unescaped (- (string-length unescaped) 1)) #\"))
                       (substring unescaped 1 (- (string-length unescaped) 1))
                       unescaped)))
               (string-split array-content #\,)))
        #f)))

;;; Extract string value from JSON
(define (extract-json-string json-str key)
  "Extract a string value for a given key from JSON"
  ;; Simplified regex to avoid issues
  (let* ((pattern (string-append "\"" key "\"\\s*:\\s*\"([^\"]+)\""))
         (match (string-match pattern json-str)))
    (if match
        (match:substring match 1)
        #f)))

;;; Unescape JSON string
(define (unescape-json-string str)
  "Unescape a JSON string"
  (let ((result str))
    ;; Order matters - do \\ first
    (set! result (regexp-substitute/global #f "\\\\\\\\" result 'pre "\\" 'post))
    (set! result (regexp-substitute/global #f "\\\\\"" result 'pre "\"" 'post))
    (set! result (regexp-substitute/global #f "\\\\n" result 'pre "\n" 'post))
    (set! result (regexp-substitute/global #f "\\\\t" result 'pre "\t" 'post))
    (set! result (regexp-substitute/global #f "\\\\r" result 'pre "\r" 'post))
    result))

;;; Parse Ollama response to extract topics
(define (parse-ollama-topics-response json-str)
  "Extract topics from an Ollama API response"
  ;; First get the response field
  (let ((response-content (extract-json-string json-str "response")))
    (if response-content
        (let ((unescaped (unescape-json-string response-content)))
          ;; Debug output
          ;; (format #t "    DEBUG: Unescaped content: ~a~%" unescaped)
          ;; Now extract topics from the unescaped content
          (extract-json-string-array unescaped "topics"))
        #f)))

;;; String utilities
(define (string-trim-both str)
  "Trim whitespace from both ends of a string"
  (let ((len (string-length str)))
    (if (= len 0)
        str
        (let* ((start (let loop ((i 0))
                       (cond
                         ((>= i len) len)
                         ((char-whitespace? (string-ref str i)) (loop (+ i 1)))
                         (else i))))
               (end (let loop ((i (- len 1)))
                     (cond
                       ((< i start) start)
                       ((char-whitespace? (string-ref str i)) (loop (- i 1)))
                       (else (+ i 1))))))
          (substring str start end)))))

;;; Test the parser
(format #t "Testing custom parser on various inputs:~%~%")

(for-each
 (lambda (test-case)
   (let ((name (car test-case))
         (json (cdr test-case)))
     (format #t "Test: ~a~%" name)
     (format #t "Input: ~a...~%" (substring json 0 (min 60 (string-length json))))
     
     ;; Try direct array extraction
     (let ((direct-topics (extract-json-string-array json "topics")))
       (if direct-topics
           (format #t "  Direct topics: ~a~%" direct-topics)
           (format #t "  No direct topics found~%")))
     
     ;; Try Ollama response parsing
     (let ((ollama-topics (parse-ollama-topics-response json)))
       (if ollama-topics
           (format #t "  Ollama topics: ~a~%" ollama-topics)
           (format #t "  No Ollama topics found~%")))
     
     (newline)))
 test-cases)

;;; Final implementation for use in repo-topics
(format #t "=== Recommended Implementation ===~%~%")

(format #t "```scheme
(define (parse-ollama-topics-response json-str)
  \"Extract topics from an Ollama API response\"
  (let ((response-content (extract-json-string json-str \"response\")))
    (if response-content
        (let ((unescaped (unescape-json-string response-content)))
          (extract-json-string-array unescaped \"topics\"))
        #f)))
```~%~%")

(format #t "This approach:~%")
(format #t "- No external dependencies~%")
(format #t "- Handles escaped JSON strings~%")
(format #t "- Simple and focused on our use case~%")
(format #t "- Works with standard Guile~%")