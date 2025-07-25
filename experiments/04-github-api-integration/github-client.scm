#!/usr/bin/env guile
!#
;;; github-client.scm - Basic GitHub REST API client in Scheme

(use-modules (ice-9 popen)
             (ice-9 rdelim)
             (ice-9 format)
             (ice-9 match)
             (srfi srfi-1))

;;; Configuration from environment
(define github-token (getenv "GITHUB_TOKEN"))
(define github-api-url (or (getenv "GITHUB_API_URL") "https://api.github.com"))

;;; HTTP client using curl
(define (http-request method url #:key (headers '()) (body #f))
  "Make HTTP request and return response with headers"
  (let* ((auth-headers (if github-token
                          (cons (format #f "Authorization: Bearer ~a" github-token) headers)
                          headers))
         (header-args (string-join
                      (map (lambda (h) (format #f "-H '~a'" h)) auth-headers)
                      " "))
         (body-arg (if body (format #f "-d '~a'" body) ""))
         (cmd (format #f "curl -i -s -X ~a ~a ~a '~a'" 
                     method header-args body-arg url)))
    
    ;; Execute request
    (let* ((port (open-pipe* OPEN_READ "/bin/sh" "-c" cmd))
           (output (read-string port)))
      (close-pipe port)
      (parse-http-response output))))

(define (parse-http-response response)
  "Parse HTTP response into headers and body"
  (let* ((lines (string-split response #\newline))
         (header-end (list-index (lambda (line) (string=? line "")) lines)))
    (if header-end
        (let ((headers (take lines header-end))
              (body (string-join (drop lines (+ header-end 1)) "\n")))
          (list (cons 'headers (parse-headers headers))
                (cons 'body body)))
        (list (cons 'headers '())
              (cons 'body response)))))

(define (parse-headers header-lines)
  "Parse header lines into alist"
  (filter-map
   (lambda (line)
     (let ((colon-pos (string-index line #\:)))
       (if (and colon-pos (> colon-pos 0))
           (cons (string-downcase (substring line 0 colon-pos))
                 (string-trim (substring line (+ colon-pos 1))))
           #f)))
   header-lines))

;;; GitHub API specific functions
(define (github-get endpoint)
  "GET request to GitHub API"
  (http-request "GET" (format #f "~a~a" github-api-url endpoint)
                #:headers '("Accept: application/vnd.github.v3+json")))

(define (github-post endpoint body)
  "POST request to GitHub API"
  (http-request "POST" (format #f "~a~a" github-api-url endpoint)
                #:headers '("Accept: application/vnd.github.v3+json"
                          "Content-Type: application/json")
                #:body body))

(define (get-rate-limit response)
  "Extract rate limit info from response headers"
  (let ((headers (assoc-ref response 'headers)))
    (list (cons 'limit (string->number 
                       (or (assoc-ref headers "x-ratelimit-limit") "60")))
          (cons 'remaining (string->number 
                           (or (assoc-ref headers "x-ratelimit-remaining") "0")))
          (cons 'reset (string->number 
                       (or (assoc-ref headers "x-ratelimit-reset") "0"))))))

(define (parse-link-header link-header)
  "Parse GitHub Link header for pagination"
  (if link-header
      (map (lambda (link)
             (match (string-split (string-trim link) #\;)
               ((url-part rel-part)
                (let ((url (string-trim (string-trim url-part) #\< #\>))
                      (rel (cadr (string-split rel-part #\=))))
                  (cons (string-trim rel #\") url)))
               (_ #f)))
           (string-split link-header #\,))
      '()))

;;; JSON parsing (simplified)
(define (parse-json-simple json-str)
  "Simple JSON array/object detection"
  (cond
    ((string-prefix? "[" (string-trim json-str))
     (format #t "JSON array response~%"))
    ((string-prefix? "{" (string-trim json-str))
     (format #t "JSON object response~%"))
    (else
     (format #t "Unknown response format~%"))))

;;; Example usage
(define (example-usage)
  (format #t "GitHub API Client Example~%")
  (format #t "========================~%~%")
  
  (if (not github-token)
      (begin
        (format #t "Warning: GITHUB_TOKEN not set. Using unauthenticated requests.~%")
        (format #t "Set with: export GITHUB_TOKEN=your_token_here~%~%")))
  
  ;; Get current user
  (format #t "1. Getting current user...~%")
  (let ((response (github-get "/user")))
    (format #t "Rate limit: ~a~%" (get-rate-limit response))
    (parse-json-simple (assoc-ref response 'body))
    (newline))
  
  ;; Get public repos
  (format #t "2. Getting public repositories...~%")
  (let ((response (github-get "/user/repos?per_page=5")))
    (format #t "Rate limit: ~a~%" (get-rate-limit response))
    (let ((link-header (assoc-ref (assoc-ref response 'headers) "link")))
      (if link-header
          (format #t "Pagination links: ~a~%" (parse-link-header link-header))))
    (newline)))

;; Run example if executed directly
(when (equal? (car (command-line)) "github-client.scm")
  (example-usage))