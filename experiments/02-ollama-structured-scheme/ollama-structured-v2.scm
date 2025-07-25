#!/usr/bin/env guile
!#
;;; ollama-structured-v2.scm - Improved version with better JSON handling
;;; Uses temporary files to avoid shell escaping issues

(use-modules (ice-9 format)
             (ice-9 popen)
             (ice-9 rdelim)
             (ice-9 regex)
             (ice-9 match)
             (srfi srfi-1))

;;; ANSI color codes
(define *green* "\x1b[0;32m")
(define *red* "\x1b[0;31m")
(define *blue* "\x1b[0;34m")
(define *reset* "\x1b[0m")

;;; Escape string for JSON
(define (json-escape-string str)
  "Properly escape a string for JSON"
  (let ((chars (string->list str)))
    (list->string
     (fold (lambda (ch acc)
             (append acc
                     (case ch
                       ((#\") '(#\\ #\"))
                       ((#\\) '(#\\ #\\))
                       ((#\newline) '(#\\ #\n))
                       ((#\return) '(#\\ #\r))
                       ((#\tab) '(#\\ #\t))
                       (else (list ch)))))
           '()
           chars))))

;;; Create JSON string from Scheme data (improved)
(define (scm->json-string data)
  "Convert Scheme data structure to JSON string"
  (cond
    ((null? data) "null")
    ((boolean? data) (if data "true" "false"))
    ((number? data) (number->string data))
    ((string? data) (format #f "\"~a\"" (json-escape-string data)))
    ((symbol? data) (format #f "\"~a\"" (json-escape-string (symbol->string data))))
    ((list? data)
     (if (and (pair? data) (pair? (car data)) (symbol? (caar data)))
         ;; Object (association list)
         (string-append "{"
                       (string-join
                        (map (lambda (pair)
                               (format #f "\"~a\":~a"
                                      (json-escape-string (symbol->string (car pair)))
                                      (scm->json-string (cdr pair))))
                             data)
                        ",")
                       "}")
         ;; Array
         (string-append "["
                       (string-join (map scm->json-string data) ",")
                       "]")))
    (else "null")))

;;; Write JSON to temporary file and make request
(define (ollama-request-v2 endpoint body)
  "Make POST request to Ollama API using temp file"
  (let* ((json-body (scm->json-string body))
         (temp-file (format #f "/tmp/ollama-req-~a.json" (getpid))))
    ;; Write JSON to temp file
    (call-with-output-file temp-file
      (lambda (port)
        (display json-body port)))
    
    ;; Make request using temp file
    (let* ((cmd (format #f "curl -X POST http://localhost:11434~a -H 'Content-Type: application/json' -d @~a -s 2>/dev/null"
                       endpoint temp-file))
           (port (open-pipe* OPEN_READ "/bin/sh" "-c" cmd))
           (response (read-string port))
           (status (close-pipe port)))
      ;; Clean up temp file
      (delete-file temp-file)
      (if (zero? (status:exit-val status))
          response
          #f))))

;;; Extract message content from Ollama response
(define (extract-message response)
  "Extract the message content from Ollama response"
  (let ((pattern "\"message\"\\s*:\\s*\\{[^}]*\"content\"\\s*:\\s*\"([^\"]+)\""))
    (match (string-match pattern response)
      (#f #f)
      (m (match:substring m 1)))))

;;; Run a simple test
(define (test-simple)
  (format #t "~a=== Simple Ollama Test ===~a~%" *blue* *reset*)
  (let* ((request-body
          '((model . "llama3.2:3b")
            (prompt . "List 3 programming languages as JSON: {\"languages\": [...]}")
            (stream . #f)
            (format . ((type . "object")
                      (properties . ((languages . ((type . "array")
                                                  (items . ((type . "object")
                                                           (properties . ((name . ((type . "string")))
                                                                        (use_case . ((type . "string")))))
                                                           (required . ("name" "use_case"))))))))
                      (required . ("languages"))))))
         (response (ollama-request-v2 "/api/generate" request-body)))
    
    (if response
        (begin
          (format #t "~aSuccess!~a~%" *green* *reset*)
          (format #t "Response length: ~a characters~%" (string-length response))
          (let ((content (extract-message response)))
            (if content
                (format #t "Content: ~a~%" content)
                (format #t "Could not extract content~%"))))
        (format #t "~aFailed to get response~a~%" *red* *reset*))))

;;; Main
(format #t "~a=== Ollama Structured Output V2 (Scheme) ===~a~%" *blue* *reset*)
(format #t "Using temporary files for JSON requests~%~%")
(test-simple)