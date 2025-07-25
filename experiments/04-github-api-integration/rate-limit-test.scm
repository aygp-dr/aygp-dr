#!/usr/bin/env guile
!#
;;; rate-limit-test.scm - Test GitHub API rate limiting

(load "github-client.scm")

(use-modules (ice-9 format)
             (srfi srfi-19))  ; For time operations

;;; Rate limit tracking
(define current-rate-limit #f)

(define (update-rate-limit response)
  "Update global rate limit from response"
  (set! current-rate-limit (get-rate-limit response))
  current-rate-limit)

(define (seconds-until-reset)
  "Calculate seconds until rate limit reset"
  (if (and current-rate-limit (assoc-ref current-rate-limit 'reset))
      (max 0 (- (assoc-ref current-rate-limit 'reset)
                (current-time)))
      0))

(define (should-backoff?)
  "Check if we should back off from API calls"
  (and current-rate-limit
       (< (assoc-ref current-rate-limit 'remaining) 10)))

(define (wait-for-reset)
  "Wait until rate limit resets"
  (let ((wait-time (seconds-until-reset)))
    (when (> wait-time 0)
      (format #t "Rate limit low. Waiting ~a seconds...~%" wait-time)
      (sleep wait-time))))

;;; Exponential backoff
(define (exponential-backoff attempt max-attempts)
  "Calculate backoff time with exponential increase"
  (if (< attempt max-attempts)
      (let ((wait-time (expt 2 attempt)))
        (format #t "Backing off for ~a seconds (attempt ~a/~a)~%"
                wait-time attempt max-attempts)
        (sleep wait-time)
        #t)
      #f))

;;; Rate limit aware request
(define (github-get-with-limit endpoint)
  "Make GitHub request with rate limit awareness"
  (when (should-backoff?)
    (wait-for-reset))
  
  (let ((response (github-get endpoint)))
    (update-rate-limit response)
    response))

;;; Test functions
(define (test-rate-limits)
  "Test rate limit detection and handling"
  (format #t "Rate Limit Testing~%")
  (format #t "==================~%~%")
  
  ;; Check initial rate limit
  (format #t "1. Checking rate limit status...~%")
  (let ((response (github-get "/rate_limit")))
    (update-rate-limit response)
    (format #t "Current limits: ~a~%" current-rate-limit)
    (format #t "Reset in: ~a seconds~%~%" (seconds-until-reset)))
  
  ;; Make a few requests
  (format #t "2. Making sequential requests...~%")
  (for-each
   (lambda (i)
     (format #t "Request ~a: " (+ i 1))
     (let ((response (github-get-with-limit "/user")))
       (format #t "Remaining: ~a~%" 
               (assoc-ref current-rate-limit 'remaining))))
   (iota 5))
  
  ;; Test backoff
  (format #t "~%3. Testing exponential backoff...~%")
  (for-each
   (lambda (attempt)
     (exponential-backoff attempt 5))
   (iota 3)))

(define (test-parallel-requests)
  "Test handling parallel requests"
  (format #t "~%Parallel Request Testing~%")
  (format #t "========================~%~%")
  
  ;; Simulate parallel requests
  (format #t "Simulating 10 parallel requests...~%")
  (let ((endpoints (map (lambda (i) 
                         (format #f "/users/octocat/repos?page=~a" i))
                       (iota 10 1))))
    (for-each
     (lambda (endpoint)
       (let ((response (github-get-with-limit endpoint)))
         (format #t "Request to ~a - Remaining: ~a~%"
                 endpoint
                 (assoc-ref current-rate-limit 'remaining))))
     endpoints)))

;;; Run tests
(define (main)
  (test-rate-limits)
  (test-parallel-requests)
  
  (format #t "~%Rate limit tests complete!~%")
  (format #t "Final rate limit status: ~a~%" current-rate-limit))

;; Helper for current time in seconds
(define (current-time)
  (inexact->exact (floor (time-second (current-time-utc)))))

;; Run if executed directly
(when (equal? (basename (car (command-line))) "rate-limit-test.scm")
  (main))