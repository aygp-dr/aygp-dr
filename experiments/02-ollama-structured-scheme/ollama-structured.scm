#!/usr/bin/env guile
!#
;;; ollama-structured.scm - Test Ollama structured output with Guile Scheme
;;; Demonstrates making HTTP requests to Ollama API with structured JSON schemas

(use-modules (ice-9 format)
             (ice-9 popen)
             (ice-9 rdelim)
             (ice-9 match)
             (ice-9 regex)
             (srfi srfi-1))

;;; ANSI color codes
(define *green* "\x1b[0;32m")
(define *red* "\x1b[0;31m")
(define *blue* "\x1b[0;34m")
(define *reset* "\x1b[0m")

;;; Create JSON string from Scheme data
(define (scm->json-string data)
  "Convert Scheme data structure to JSON string"
  (cond
    ((null? data) "null")
    ((boolean? data) (if data "true" "false"))
    ((number? data) (number->string data))
    ((string? data) (format #f "~s" data))
    ((list? data)
     (if (and (pair? data) (pair? (car data)) (symbol? (caar data)))
         ;; Object (association list)
         (string-append "{"
                       (string-join
                        (map (lambda (pair)
                               (format #f "~s:~a"
                                      (symbol->string (car pair))
                                      (scm->json-string (cdr pair))))
                             data)
                        ",")
                       "}")
         ;; Array
         (string-append "["
                       (string-join (map scm->json-string data) ",")
                       "]")))
    (else (error "Cannot convert to JSON:" data))))

;;; Make HTTP POST request to Ollama
(define (ollama-request endpoint body)
  "Make POST request to Ollama API"
  (let* ((json-body (scm->json-string body))
         (cmd (format #f "curl -X POST http://localhost:11434~a -H 'Content-Type: application/json' -d '~a' -s"
                     endpoint
                     (string-map (lambda (c)
                                  (if (char=? c #\') #\space c))
                                json-body))))
    (let* ((port (open-pipe* OPEN_READ "/bin/sh" "-c" cmd))
           (response (read-string port)))
      (close-pipe port)
      response)))

;;; Parse simple JSON response
(define (parse-json-value str key)
  "Extract a value from JSON string by key"
  (let ((pattern (format #f "\"~a\"\\s*:\\s*\"([^\"]*)\"" key)))
    (match (string-match pattern str)
      (#f #f)
      (m (match:substring m 1)))))

;;; Test 1: Lean4 repository analysis
(define (test-lean4-analysis)
  (format #t "~aTest 1: Lean4 Repository Analysis~a~%" *blue* *reset*)
  (format #t "~a~a~a~%" *blue* (make-string 40 #\-) *reset*)
  
  (let* ((format-schema
          '((type . "object")
            (properties . ((repository . ((type . "string")))
                          (description . ((type . "string")))
                          (main_topics . ((type . "array")
                                        (items . ((type . "string")))))
                          (key_features . ((type . "array")
                                         (items . ((type . "string")))))
                          (use_cases . ((type . "array")
                                      (items . ((type . "string")))))))
            (required . ("repository" "description" "main_topics" "key_features" "use_cases"))))
         (request-body
          `((model . "llama3.1")
            (messages . (((role . "user")
                         (content . "List the main topics and features of the Lean4 programming language GitHub repository (leanprover/lean4). Include areas like theorem proving, functional programming features, and key components."))))
            (stream . #f)
            (format . ,format-schema))))
    
    (format #t "Sending request to Ollama...~%")
    (let ((response (ollama-request "/api/chat" request-body)))
      (if (string-contains response "content")
          (begin
            (format #t "~a✓ Received response~a~%" *green* *reset*)
            (call-with-output-file "output/scheme-test1-lean4.json"
              (lambda (port)
                (display response port)))
            (format #t "Response saved to output/scheme-test1-lean4.json~%"))
          (format #t "~a✗ Failed to get valid response~a~%" *red* *reset*)))
    
    (newline)))

;;; Test 2: Repository metadata suggestions
(define (test-metadata-suggestions)
  (format #t "~aTest 2: Repository Metadata Suggestions~a~%" *blue* *reset*)
  (format #t "~a~a~a~%" *blue* (make-string 40 #\-) *reset*)
  
  (let* ((format-schema
          '((type . "object")
            (properties . ((suggested_description . ((type . "string")
                                                   (maxLength . 350)))
                          (suggested_topics . ((type . "array")
                                             (items . ((type . "string")
                                                     (pattern . "^[a-z0-9-]+$")))
                                             (minItems . 3)
                                             (maxItems . 20)))
                          (rationale . ((type . "string")))))
            (required . ("suggested_description" "suggested_topics" "rationale"))))
         (request-body
          `((model . "llama3.1")
            (messages . (((role . "user")
                         (content . "Suggest GitHub repository metadata (description and topics) for a Scheme implementation of a GitHub repository metadata checker that uses the GitHub API."))))
            (stream . #f)
            (format . ,format-schema))))
    
    (format #t "Sending request to Ollama...~%")
    (let ((response (ollama-request "/api/chat" request-body)))
      (if (string-contains response "content")
          (begin
            (format #t "~a✓ Received response~a~%" *green* *reset*)
            (call-with-output-file "output/scheme-test2-metadata.json"
              (lambda (port)
                (display response port)))
            (format #t "Response saved to output/scheme-test2-metadata.json~%"))
          (format #t "~a✗ Failed to get valid response~a~%" *red* *reset*)))
    
    (newline)))

;;; Test 3: Complex API analysis
(define (test-api-analysis)
  (format #t "~aTest 3: GitHub API Analysis~a~%" *blue* *reset*)
  (format #t "~a~a~a~%" *blue* (make-string 40 #\-) *reset*)
  
  (let* ((operation-schema
          '((type . "object")
            (properties . ((endpoint . ((type . "string")))
                          (description . ((type . "string")))
                          (http_method . ((type . "string")))))))
         (format-schema
          `((type . "object")
            (properties . ((api_analysis . ((type . "object")
                                          (properties . ((read_operations . ((type . "array")
                                                                           (items . ,operation-schema)))
                                                        (write_operations . ((type . "array")
                                                                           (items . ,operation-schema)))
                                                        (authentication_required . ((type . "boolean")))))))))
            (required . ("api_analysis"))))
         (request-body
          `((model . "llama3.1")
            (messages . (((role . "user")
                         (content . "Analyze the GitHub API endpoints for repository management and categorize them by operation type."))))
            (stream . #f)
            (format . ,format-schema))))
    
    (format #t "Sending request to Ollama...~%")
    (let ((response (ollama-request "/api/chat" request-body)))
      (if (string-contains response "content")
          (begin
            (format #t "~a✓ Received response~a~%" *green* *reset*)
            (call-with-output-file "output/scheme-test3-api.json"
              (lambda (port)
                (display response port)))
            (format #t "Response saved to output/scheme-test3-api.json~%"))
          (format #t "~a✗ Failed to get valid response~a~%" *red* *reset*)))
    
    (newline)))

;;; Check if Ollama is running
(define (check-ollama)
  "Check if Ollama server is accessible"
  (let* ((cmd "curl -s http://localhost:11434/api/tags")
         (port (open-pipe* OPEN_READ "/bin/sh" "-c" cmd))
         (response (read-string port))
         (status (close-pipe port)))
    (not (eof-object? response))))

;;; Main program
(define (main)
  (format #t "~a=== Ollama Structured Output Experiment (Scheme) ===~a~%" *blue* *reset*)
  (format #t "Testing structured JSON output format with Ollama API~%")
  (format #t "~a~a~a~%~%" *blue* (make-string 50 #\=) *reset*)
  
  ;; Check if Ollama is running
  (if (not (check-ollama))
      (begin
        (format #t "~aError: Ollama is not running on localhost:11434~a~%" *red* *reset*)
        (format #t "Please start Ollama with: ollama serve~%")
        (exit 1)))
  
  ;; Create output directory
  (system "mkdir -p output")
  
  ;; Run tests
  (test-lean4-analysis)
  (test-metadata-suggestions)
  (test-api-analysis)
  
  (format #t "~a=== Summary ===~a~%" *blue* *reset*)
  (format #t "All test outputs saved to ./output/~%")
  (format #t "~%Validating outputs...~%")
  
  ;; Check output files
  (for-each
   (lambda (file)
     (if (file-exists? file)
         (format #t "~a: ~a✓ Created~a~%"
                (basename file)
                *green* *reset*)
         (format #t "~a: ~a✗ Missing~a~%"
                (basename file)
                *red* *reset*)))
   '("output/scheme-test1-lean4.json"
     "output/scheme-test2-metadata.json"
     "output/scheme-test3-api.json"))
  
  (format #t "~%~aExperiment complete!~a~%" *green* *reset*))

;;; Helper function to get basename
(define (basename path)
  (let ((parts (string-split path #\/)))
    (last parts)))

;;; Helper function for string-contains
(define (string-contains str substr)
  (if (string-match substr str) #t #f))

;;; Run the main program
(main)