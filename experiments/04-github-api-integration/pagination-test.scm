#!/usr/bin/env guile
!#
;;; pagination-test.scm - Test GitHub API pagination

(load "github-client.scm")

(use-modules (ice-9 format)
             (ice-9 regex)
             (srfi srfi-1))

;;; Pagination utilities
(define (get-next-url response)
  "Extract next page URL from Link header"
  (let* ((headers (assoc-ref response 'headers))
         (link-header (assoc-ref headers "link")))
    (if link-header
        (let ((links (parse-link-header link-header)))
          (assoc-ref links "next"))
        #f)))

(define (get-last-page response)
  "Extract last page number from Link header"
  (let* ((headers (assoc-ref response 'headers))
         (link-header (assoc-ref headers "link")))
    (if link-header
        (let ((links (parse-link-header link-header))
              (last-url (assoc-ref links "last")))
          (if last-url
              (let ((match (string-match "page=([0-9]+)" last-url)))
                (if match
                    (string->number (match:substring match 1))
                    1))
              1))
        1)))

(define (github-get-all-pages endpoint)
  "Fetch all pages for a paginated endpoint"
  (format #t "Fetching all pages for: ~a~%" endpoint)
  
  (let loop ((url (format #f "~a~a" github-api-url endpoint))
             (pages '())
             (page-num 1))
    (format #t "Fetching page ~a...~%" page-num)
    
    (let* ((response (http-request "GET" url
                                  #:headers (list "Accept: application/vnd.github.v3+json"
                                                 (format #f "Authorization: Bearer ~a" github-token))))
           (next-url (get-next-url response)))
      
      (if next-url
          (loop next-url 
                (cons response pages) 
                (+ page-num 1))
          (begin
            (format #t "Total pages fetched: ~a~%" page-num)
            (reverse (cons response pages)))))))

(define (count-items-per-page pages)
  "Count items in each page (assuming JSON array responses)"
  (map (lambda (page idx)
         (let ((body (assoc-ref page 'body)))
           ;; Simple count of array items by counting commas
           (let ((item-count (+ 1 (length (string-split body #\,)))))
             (format #t "Page ~a: ~a items (estimated)~%" 
                     (+ idx 1) item-count)
             item-count)))
       pages
       (iota (length pages))))

;;; Test scenarios
(define (test-simple-pagination)
  "Test basic pagination"
  (format #t "~%Simple Pagination Test~%")
  (format #t "=====================~%~%")
  
  ;; Get first page with small page size
  (let ((response (github-get "/user/repos?per_page=5")))
    (format #t "First page response received~%")
    (format #t "Total pages available: ~a~%" (get-last-page response))
    
    (let ((next-url (get-next-url response)))
      (if next-url
          (format #t "Next page URL: ~a~%" next-url)
          (format #t "No next page available~%"))))
  
  (newline))

(define (test-full-pagination)
  "Test fetching all pages"
  (format #t "Full Pagination Test~%")
  (format #t "===================~%~%")
  
  ;; Fetch all starred repos (usually paginated)
  (let ((pages (github-get-all-pages "/user/starred?per_page=10")))
    (format #t "~%Summary:~%")
    (format #t "Total pages retrieved: ~a~%" (length pages))
    (count-items-per-page pages))
  
  (newline))

(define (test-search-pagination)
  "Test pagination with search results"
  (format #t "Search Pagination Test~%")
  (format #t "=====================~%~%")
  
  ;; Search for Scheme repositories
  (let ((response (github-get "/search/repositories?q=language:scheme&per_page=10")))
    (format #t "Search response received~%")
    
    ;; Extract total count from response (would need JSON parsing)
    (let ((body (assoc-ref response 'body)))
      (let ((match (string-match "\"total_count\":\\s*([0-9]+)" body)))
        (if match
            (format #t "Total results: ~a~%" (match:substring match 1)))))
    
    (format #t "Pages available: ~a~%" (get-last-page response))))

(define (test-cursor-pagination)
  "Test GraphQL-style cursor pagination (simulation)"
  (format #t "~%Cursor Pagination Test~%")
  (format #t "=====================~%~%")
  
  (format #t "Note: GitHub REST API uses page-based pagination.~%")
  (format #t "GraphQL API uses cursor-based pagination.~%")
  (format #t "This would require GraphQL endpoint testing.~%"))

;;; Main test runner
(define (main)
  (format #t "GitHub Pagination Testing~%")
  (format #t "========================~%")
  
  (if (not github-token)
      (begin
        (format #t "Error: GITHUB_TOKEN required for pagination tests~%")
        (exit 1)))
  
  (test-simple-pagination)
  (test-full-pagination)
  (test-search-pagination)
  (test-cursor-pagination)
  
  (format #t "~%Pagination tests complete!~%"))

;; Helper functions
(define (basename path)
  (let ((parts (string-split path #\/)))
    (last parts)))

;; Run if executed directly
(when (equal? (basename (car (command-line))) "pagination-test.scm")
  (main))