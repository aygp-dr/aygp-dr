#!/usr/bin/env guile
!#
;;; json-parser-proper.scm - Proper JSON parsing approaches

(use-modules (ice-9 format)
             (ice-9 popen)
             (ice-9 rdelim)
             (srfi srfi-1))

(format #t "=== Proper JSON Parsing for Ollama Responses ===~%~%")

;;; Method 1: Using jq (if available)
(define (jq-available?)
  "Check if jq is installed"
  (zero? (system* "which" "jq")))

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

;;; Method 2: Try to use guile-json if available
(define (try-guile-json)
  "Try to load guile-json module"
  (catch #t
    (lambda ()
      (use-modules (json))
      (format #t "✓ guile-json is available!~%")
      #t)
    (lambda (key . args)
      (format #t "✗ guile-json not installed~%")
      #f)))

;;; Method 3: Use simpler Ollama prompt format
(define (parse-simple-topics response)
  "Parse topics from a simpler format"
  ;; If we ask Ollama to return topics one per line
  (string-split response #\newline))

;;; Method 4: Minimal working extractor for our specific case
(define (extract-topics-minimal json-str)
  "Extract topics using a more careful approach"
  ;; This is still fragile but better than pure regex
  (catch #t
    (lambda ()
      ;; Find the response field
      (let ((response-start (string-contains json-str "\"response\":\"")))
        (if response-start
            (let* ((content-start (+ response-start 12))
                   (content-end (string-index json-str #\" content-start))
                   (response-content (substring json-str content-start content-end)))
              ;; Unescape the content
              (let ((unescaped (simple-unescape response-content)))
                ;; Find topics array
                (let ((topics-start (string-contains unescaped "["))
                      (topics-end (string-contains unescaped "]")))
                  (if (and topics-start topics-end)
                      (let ((topics-str (substring unescaped 
                                                  (+ topics-start 1) 
                                                  topics-end)))
                        ;; Parse individual topics
                        (map (lambda (topic)
                               (string-trim-both 
                                (string-trim-both topic #\")
                                #\space))
                             (string-split topics-str #\,)))
                      #f))))
            #f)))
    (lambda (key . args)
      #f)))

(define (simple-unescape str)
  "Simple unescaping for common cases"
  (let ((result str))
    (set! result (string-replace-all result "\\\"" "\""))
    (set! result (string-replace-all result "\\\\" "\\"))
    result))

(define (string-replace-all str old new)
  "Replace all occurrences of old with new"
  (let ((old-len (string-length old)))
    (let loop ((start 0) (result ""))
      (let ((pos (string-contains str old start)))
        (if pos
            (loop (+ pos old-len)
                  (string-append result 
                                (substring str start pos)
                                new))
            (string-append result (substring str start)))))))

(define (string-contains haystack needle . start)
  "Find needle in haystack"
  (let ((start-pos (if (null? start) 0 (car start))))
    (let loop ((i start-pos))
      (cond
        ((> (+ i (string-length needle)) (string-length haystack)) #f)
        ((string=? (substring haystack i (+ i (string-length needle))) needle) i)
        (else (loop (+ i 1)))))))

(define (string-trim-both str . chars)
  "Trim characters from both ends"
  (let ((char-to-trim (if (null? chars) #\space (car chars))))
    (let* ((len (string-length str))
           (start (let loop ((i 0))
                   (if (and (< i len) (char=? (string-ref str i) char-to-trim))
                       (loop (+ i 1))
                       i)))
           (end (let loop ((i (- len 1)))
                 (if (and (>= i start) (char=? (string-ref str i) char-to-trim))
                     (loop (- i 1))
                     (+ i 1)))))
      (if (> end start)
          (substring str start end)
          ""))))

;;; Test the methods
(define test-response "{\"model\":\"llama3.2:3b\",\"response\":\"{\\\"topics\\\": [\\\"scheme\\\", \\\"lisp\\\", \\\"functional-programming\\\", \\\"ollama\\\", \\\"github-api\\\"]}\",\"done\":true}")

(format #t "Testing with sample Ollama response:~%~%")

;; Test jq method
(if (jq-available?)
    (begin
      (format #t "Method 1 (jq): ")
      (let ((topics (parse-topics-with-jq test-response)))
        (format #t "~a~%" topics)))
    (format #t "Method 1 (jq): Not available~%"))

;; Test guile-json
(format #t "Method 2 (guile-json): ")
(try-guile-json)

;; Test minimal extractor
(format #t "Method 3 (minimal extractor): ")
(let ((topics (extract-topics-minimal test-response)))
  (format #t "~a~%" (or topics "Failed")))

(format #t "~%=== Recommendation ===~%")
(format #t "For the repo-topics tool:~%")
(format #t "1. Check if jq is available and use it~%")
(format #t "2. Fall back to minimal extractor~%")
(format #t "3. Provide clear error if both fail~%")
(format #t "4. Document that guile-json is preferred for production~%")