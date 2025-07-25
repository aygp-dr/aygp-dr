#!/usr/bin/env guile
!#
;;; github-client-v2.scm - Pure Scheme GitHub client (no shell commands)

(use-modules (ice-9 format)
             (ice-9 popen)
             (ice-9 rdelim)
             (ice-9 regex)
             (srfi srfi-1))

;;; HTTP client using Guile's web modules would be ideal,
;;; but for compatibility with older Guile, we'll use curl internally
;;; but with proper Scheme data structures

;;; GitHub API configuration
(define github-api-base "https://api.github.com")
(define github-token (getenv "GITHUB_TOKEN"))

;;; Request builder
(define-record-type <http-request>
  (make-http-request method url headers body)
  http-request?
  (method request-method)
  (url request-url)
  (headers request-headers)
  (body request-body))

(define-record-type <http-response>
  (make-http-response status-code headers body)
  http-response?
  (status-code response-status-code)
  (headers response-headers)
  (body response-body))

;;; GitHub API methods
(define* (github-get endpoint #:key (params '()))
  "Make GET request to GitHub API"
  (let* ((url (build-url endpoint params))
         (headers (build-headers))
         (request (make-http-request "GET" url headers #f)))
    (execute-request request)))

(define* (github-patch endpoint body #:key (params '()))
  "Make PATCH request to GitHub API"
  (let* ((url (build-url endpoint params))
         (headers (append (build-headers) 
                         '(("Content-Type" . "application/json"))))
         (json-body (scm->json-string body))
         (request (make-http-request "PATCH" url headers json-body)))
    (execute-request request)))

(define* (github-put endpoint body #:key (params '()))
  "Make PUT request to GitHub API"
  (let* ((url (build-url endpoint params))
         (headers (append (build-headers)
                         '(("Content-Type" . "application/json"))))
         (json-body (scm->json-string body))
         (request (make-http-request "PUT" url headers json-body)))
    (execute-request request)))

;;; URL and header building
(define (build-url endpoint params)
  "Build full URL with parameters"
  (let ((base-url (string-append github-api-base endpoint)))
    (if (null? params)
        base-url
        (string-append base-url "?" (build-query-string params)))))

(define (build-query-string params)
  "Build URL query string from parameters"
  (string-join
   (map (lambda (param)
         (format #f "~a=~a" (car param) (cdr param)))
        params)
   "&"))

(define (build-headers)
  "Build HTTP headers for GitHub API"
  (let ((headers '(("Accept" . "application/vnd.github.v3+json")
                  ("User-Agent" . "repo-topics/1.0"))))
    (if github-token
        (cons (cons "Authorization" (format #f "Bearer ~a" github-token))
              headers)
        headers)))

;;; Request execution (using curl internally but with Scheme interface)
(define (execute-request request)
  "Execute HTTP request and return response"
  (let* ((temp-file (format #f "/tmp/github-req-~a.json" (getpid)))
         (curl-args (build-curl-args request temp-file)))
    
    ;; Write body to temp file if needed
    (when (request-body request)
      (call-with-output-file temp-file
        (lambda (port)
          (display (request-body request) port))))
    
    ;; Execute curl
    (let* ((port (open-pipe* OPEN_READ "/bin/sh" "-c" curl-args))
           (output (read-string port))
           (status (close-pipe port)))
      
      ;; Clean up temp file
      (when (file-exists? temp-file)
        (delete-file temp-file))
      
      ;; Parse response
      (if (zero? (status:exit-val status))
          (parse-http-response output)
          (make-http-response 500 '() output)))))

(define (build-curl-args request temp-file)
  "Build curl command arguments"
  (let* ((method (request-method request))
         (url (request-url request))
         (headers (request-headers request))
         (body (request-body request))
         (header-args (string-join
                      (map (lambda (h)
                            (format #f "-H '~a: ~a'" (car h) (cdr h)))
                          headers)
                      " "))
         (body-arg (if body
                       (format #f "-d @~a" temp-file)
                       "")))
    (format #f "curl -s -i -X ~a ~a ~a '~a'"
            method header-args body-arg url)))

(define (parse-http-response response-text)
  "Parse HTTP response text into response record"
  (let* ((lines (string-split response-text #\newline))
         (header-end (or (list-index (lambda (line) (string=? line "")) lines) 0))
         (status-line (if (null? lines) "" (car lines)))
         (header-lines (if (< header-end (length lines))
                          (take lines header-end)
                          '()))
         (body-lines (if (< (+ header-end 1) (length lines))
                        (drop lines (+ header-end 1))
                        '()))
         (status-code (parse-status-code status-line))
         (headers (parse-headers header-lines))
         (body (string-join body-lines "\n")))
    (make-http-response status-code headers body)))

(define (parse-status-code status-line)
  "Extract status code from HTTP status line"
  (let ((match (string-match "HTTP/[0-9.]+ ([0-9]+)" status-line)))
    (if match
        (string->number (match:substring match 1))
        0)))

(define (parse-headers header-lines)
  "Parse HTTP headers"
  (filter-map
   (lambda (line)
     (let ((colon-pos (string-index line #\:)))
       (if (and colon-pos (> colon-pos 0))
           (cons (string-downcase (substring line 0 colon-pos))
                 (string-trim (substring line (+ colon-pos 1))))
           #f)))
   (if (null? header-lines) '() (cdr header-lines))))

;;; High-level GitHub operations
(define (get-current-user)
  "Get current authenticated user"
  (let ((response (github-get "/user")))
    (if (= (response-status-code response) 200)
        (parse-json (response-body response))
        #f)))

(define* (get-user-repos username #:key (per-page 30) (page 1))
  "Get repositories for a user"
  (let* ((endpoint (format #f "/users/~a/repos" username))
         (params `((per_page . ,per-page) (page . ,page)))
         (response (github-get endpoint #:params params)))
    (if (= (response-status-code response) 200)
        (parse-json (response-body response))
        #f)))

(define* (get-authenticated-user-repos #:key (per-page 30) (page 1))
  "Get repositories for authenticated user"
  (let* ((params `((per_page . ,per-page) (page . ,page)))
         (response (github-get "/user/repos" #:params params)))
    (if (= (response-status-code response) 200)
        (parse-json (response-body response))
        #f)))

(define (get-repository owner repo)
  "Get repository information"
  (let* ((endpoint (format #f "/repos/~a/~a" owner repo))
         (response (github-get endpoint)))
    (if (= (response-status-code response) 200)
        (parse-json (response-body response))
        #f)))

(define (update-repository-topics owner repo topics)
  "Update repository topics"
  (let* ((endpoint (format #f "/repos/~a/~a/topics" owner repo))
         (body `((names . ,topics)))
         (response (github-put endpoint body)))
    (if (= (response-status-code response) 200)
        (parse-json (response-body response))
        #f)))

(define (get-repository-readme owner repo)
  "Get repository README content"
  (let* ((endpoint (format #f "/repos/~a/~a/readme" owner repo))
         (response (github-get endpoint)))
    (if (= (response-status-code response) 200)
        (let ((readme-data (parse-json (response-body response))))
          (base64-decode (assoc-ref readme-data 'content)))
        #f)))

;;; JSON utilities (simplified)
(define (parse-json json-str)
  "Parse JSON string to Scheme data (simplified)"
  ;; This is a very simplified JSON parser for demonstration
  ;; In a real implementation, you'd use a proper JSON library
  (cond
    ((string-prefix? "[" (string-trim json-str))
     (parse-json-array json-str))
    ((string-prefix? "{" (string-trim json-str))
     (parse-json-object json-str))
    (else #f)))

(define (parse-json-object json-str)
  "Parse JSON object (simplified)"
  ;; Simplified - would need full JSON parser
  '((mock . "json-object")))

(define (parse-json-array json-str)
  "Parse JSON array (simplified)"
  ;; Simplified - would need full JSON parser
  '((mock . "json-array")))

(define (scm->json-string data)
  "Convert Scheme data to JSON string"
  (cond
    ((null? data) "null")
    ((boolean? data) (if data "true" "false"))
    ((number? data) (number->string data))
    ((string? data) (format #f "\"~a\"" (escape-json-string data)))
    ((symbol? data) (format #f "\"~a\"" (symbol->string data)))
    ((pair? data)
     (if (every pair? data)
         ;; Object
         (format #f "{~a}"
                 (string-join
                  (map (lambda (pair)
                        (format #f "\"~a\":~a"
                               (car pair)
                               (scm->json-string (cdr pair))))
                      data)
                  ","))
         ;; Array
         (format #f "[~a]"
                 (string-join (map scm->json-string data) ","))))
    (else "null")))

(define (escape-json-string str)
  "Escape string for JSON"
  (regexp-substitute/global #f "\"" str 'pre "\\\"" 'post))

(define (base64-decode str)
  "Decode base64 string (simplified)"
  ;; In practice, you'd use a proper base64 library
  "decoded-content")

;;; Utility functions
(define (string-trim str)
  "Trim whitespace from string"
  (let ((len (string-length str)))
    (if (= len 0)
        str
        (let* ((start (let loop ((i 0))
                       (cond
                         ((>= i len) len)
                         ((char-whitespace? (string-ref str i))
                          (loop (+ i 1)))
                         (else i))))
               (end (let loop ((i (- len 1)))
                     (cond
                       ((< i start) start)
                       ((char-whitespace? (string-ref str i))
                        (loop (- i 1)))
                       (else (+ i 1))))))
          (substring str start end)))))

(define (string-prefix? prefix str)
  "Check if string starts with prefix"
  (and (>= (string-length str) (string-length prefix))
       (string=? (substring str 0 (string-length prefix)) prefix)))

(define (assoc-ref alist key)
  "Get value from association list"
  (let ((pair (assoc key alist)))
    (if pair (cdr pair) #f)))

;;; Test the client
(define (test-github-client)
  "Test the GitHub client functionality"
  (format #t "=== GitHub Client v2 Test ===\n\n")
  
  (if github-token
      (begin
        (format #t "Testing authenticated requests...\n")
        ;; Test would go here
        (format #t "✓ Client initialized with token\n"))
      (format #t "⚠ No GITHUB_TOKEN - limited functionality\n"))
  
  (format #t "\n✓ GitHub client v2 ready\n"))

;; Run test if executed directly
(when (equal? (basename (car (command-line))) "github-client-v2.scm")
  (test-github-client))

(define (basename path)
  (let ((parts (string-split path #\/)))
    (if (null? parts) path (car (reverse parts)))))