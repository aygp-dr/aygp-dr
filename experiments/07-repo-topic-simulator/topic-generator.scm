#!/usr/bin/env guile
!#
;;; topic-generator.scm - Generate repository topics using Ollama

(use-modules (ice-9 format)
             (ice-9 popen)
             (ice-9 rdelim)
             (ice-9 regex)
             (srfi srfi-1))

;;; Topic generation configuration
(define default-model "llama3.2:3b")
(define max-topics 10)
(define ollama-base-url "http://localhost:11434")

;;; Generate topics from repository data
(define* (generate-topics-from-repo repo-data #:key (model default-model))
  "Generate topics from repository analysis data"
  (let* ((readme (assoc-ref repo-data 'readme))
         (code-stats (assoc-ref repo-data 'code-stats))
         (git-info (assoc-ref repo-data 'git-info))
         (prompt (build-topic-prompt readme code-stats git-info)))
    
    (format #t "Generating topics with ~a...\n" model)
    (call-ollama-for-topics prompt model)))

(define (build-topic-prompt readme code-stats git-info)
  "Build prompt for topic generation"
  (let* ((files (if code-stats (car code-stats) '()))
         (extensions (if code-stats (cadr code-stats) (make-hash-table)))
         (file-summary (summarize-file-types extensions))
         (content-analysis (analyze-readme-content readme)))
    
    (format #f "Analyze this repository and generate exactly ~a relevant GitHub topics.

Repository Analysis:
- File types: ~a
- Content analysis: ~a

README Content (first 1500 chars):
~a

Generate topics that are:
1. Lowercase with hyphens (not spaces)
2. Specific and relevant to the project
3. Recognizable GitHub topics
4. Based on technology, purpose, and domain

Focus on:
- Programming languages used
- Frameworks and technologies
- Project type (library, tool, api, cli, etc.)
- Domain/purpose (web, ai, data, etc.)

Respond with ONLY a JSON object:
{\"topics\": [\"topic1\", \"topic2\", \"topic3\", \"topic4\", \"topic5\"]}

Do not include explanations or additional text."
            max-topics
            file-summary
            content-analysis
            (if (> (string-length readme) 1500)
                (string-append (substring readme 0 1500) "...")
                readme))))

(define (summarize-file-types extensions)
  "Create summary of file types in repository"
  (let ((type-counts (hash-fold (lambda (ext count acc)
                                 (let ((lang (extension-to-language ext)))
                                   (cons (format #f "~a (~a files)" lang count) acc)))
                               '() extensions)))
    (if (null? type-counts)
        "No code files detected"
        (string-join (take type-counts (min 5 (length type-counts))) ", "))))

(define (extension-to-language ext)
  "Map file extension to language/technology"
  (case (string->symbol (string-downcase ext))
    ((scm scheme) "Scheme")
    ((py) "Python") 
    ((js mjs) "JavaScript")
    ((ts) "TypeScript")
    ((rs) "Rust")
    ((go) "Go")
    ((java) "Java")
    ((c) "C")
    ((cpp cc cxx h hpp) "C++")
    ((rb) "Ruby")
    ((php) "PHP")
    ((swift) "Swift")
    ((kt) "Kotlin")
    ((md) "Markdown")
    ((json) "JSON")
    ((yml yaml) "YAML")
    ((toml) "TOML")
    ((dockerfile) "Docker")
    ((sh bash) "Shell")
    ((sql) "SQL")
    ((html htm) "HTML")
    ((css) "CSS")
    ((scss sass) "Sass")
    (else (string-titlecase ext))))

(define (analyze-readme-content readme)
  "Analyze README content for technology keywords"
  (let ((content (string-downcase readme))
        (keywords '()))
    
    ;; Check for common technologies
    (when (string-contains-any content '("api" "rest" "graphql"))
      (set! keywords (cons "API development" keywords)))
    
    (when (string-contains-any content '("web" "http" "server"))
      (set! keywords (cons "web development" keywords)))
    
    (when (string-contains-any content '("cli" "command" "terminal"))
      (set! keywords (cons "CLI tool" keywords)))
    
    (when (string-contains-any content '("library" "framework"))
      (set! keywords (cons "library/framework" keywords)))
    
    (when (string-contains-any content '("machine learning" "ml" "ai" "llm"))
      (set! keywords (cons "AI/ML" keywords)))
    
    (when (string-contains-any content '("database" "sql" "nosql"))
      (set! keywords (cons "database" keywords)))
    
    (when (string-contains-any content '("validation" "parser" "spec"))
      (set! keywords (cons "validation/parsing" keywords)))
    
    (when (string-contains-any content '("workflow" "automation"))
      (set! keywords (cons "automation" keywords)))
    
    (if (null? keywords)
        "general purpose"
        (string-join keywords ", "))))

(define (string-contains-any content patterns)
  "Check if content contains any of the patterns"
  (any (lambda (pattern) (string-contains content pattern)) patterns))

(define (string-contains content pattern)
  "Check if content contains pattern"
  (if (string-match pattern content) #t #f))

;;; Ollama API interaction
(define (call-ollama-for-topics prompt model)
  "Call Ollama API to generate topics"
  (let* ((request-body `((model . ,model)
                        (prompt . ,prompt)
                        (stream . #f)
                        (format . ((type . "object")
                                  (properties . ((topics . ((type . "array")
                                                          (items . ((type . "string")))
                                                          (minItems . 3)
                                                          (maxItems . ,max-topics)))))
                                  (required . ("topics"))))))
         (response (make-ollama-request request-body)))
    
    (if response
        (parse-topics-from-response response)
        (begin
          (format #t "Failed to get response from Ollama\n")
          '()))))

(define (make-ollama-request request-body)
  "Make HTTP request to Ollama"
  (let* ((json-body (scm->json-string request-body))
         (temp-file (format #f "/tmp/ollama-topics-~a.json" (getpid))))
    
    ;; Write request to temp file
    (call-with-output-file temp-file
      (lambda (port)
        (display json-body port)))
    
    ;; Make request using curl
    (let* ((cmd (format #f "curl -s -X POST ~a/api/generate -H 'Content-Type: application/json' -d @~a"
                       ollama-base-url temp-file))
           (port (open-pipe* OPEN_READ "/bin/sh" "-c" cmd))
           (response (read-string port))
           (status (close-pipe port)))
      
      ;; Clean up temp file
      (delete-file temp-file)
      
      ;; Return response if successful
      (if (zero? (status:exit-val status))
          response
          #f))))

(define (parse-topics-from-response response)
  "Extract topics from Ollama response"
  (let* ((response-match (string-match "\"response\"\\s*:\\s*\"([^\"]+)\"" response)))
    (if response-match
        (let* ((content (match:substring response-match 1))
               (unescaped (unescape-json content))
               (topics-match (string-match "\"topics\"\\s*:\\s*\\[([^\\]]+)\\]" unescaped)))
          (if topics-match
              (let ((topics-str (match:substring topics-match 1)))
                (parse-topic-list topics-str))
              (begin
                (format #t "Could not find topics in response: ~a\n" unescaped)
                '())))
        (begin
          (format #t "Could not parse Ollama response: ~a\n" (substring response 0 (min 200 (string-length response))))
          '()))))

(define (parse-topic-list topics-str)
  "Parse comma-separated topic list"
  (let ((topics (map (lambda (topic)
                      (string-trim (string-trim topic #\") #\space))
                    (string-split topics-str #\,))))
    (filter (lambda (topic) 
             (and (> (string-length topic) 0)
                  (valid-github-topic? topic)))
           topics)))

(define (valid-github-topic? topic)
  "Check if topic is valid for GitHub"
  (and (string? topic)
       (<= 1 (string-length topic) 50)
       (string-match "^[a-z0-9][a-z0-9-]*[a-z0-9]?$" topic)))

(define (unescape-json str)
  "Basic JSON string unescaping"
  (let ((result str))
    (set! result (regexp-substitute/global #f "\\\\\"" result 'pre "\"" 'post))
    (set! result (regexp-substitute/global #f "\\\\n" result 'pre "\n" 'post))
    (set! result (regexp-substitute/global #f "\\\\t" result 'pre "\t" 'post))
    result))

;;; JSON utilities (reused from other modules)
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
  (let ((result str))
    (set! result (regexp-substitute/global #f "\\\\" result 'pre "\\\\\\\\" 'post))
    (set! result (regexp-substitute/global #f "\"" result 'pre "\\\\\"" 'post))
    (set! result (regexp-substitute/global #f "\n" result 'pre "\\\\n" 'post))
    (set! result (regexp-substitute/global #f "\t" result 'pre "\\\\t" 'post))
    result))

;;; Utility functions
(define (string-downcase str)
  "Convert string to lowercase"
  (list->string (map char-downcase (string->list str))))

(define (string-titlecase str)
  "Convert string to title case"
  (if (= (string-length str) 0)
      str
      (string-append (string (char-upcase (string-ref str 0)))
                     (string-downcase (substring str 1)))))

(define (string-trim str ch)
  "Trim character from both ends of string"
  (let ((start (let loop ((i 0))
                (cond
                  ((>= i (string-length str)) (string-length str))
                  ((char=? (string-ref str i) ch) (loop (+ i 1)))
                  (else i))))
        (end (let loop ((i (- (string-length str) 1)))
              (cond
                ((< i 0) 0)
                ((char=? (string-ref str i) ch) (loop (- i 1)))
                (else (+ i 1))))))
    (if (>= start end)
        ""
        (substring str start end))))

(define (assoc-ref alist key)
  "Get value from association list"
  (let ((pair (assoc key alist)))
    (if pair (cdr pair) #f)))

;;; Test function
(define (test-topic-generator)
  "Test the topic generator"
  (format #t "=== Topic Generator Test ===\n\n")
  
  ;; Test with mock repository data
  (let* ((mock-repo-data
          `((readme . "# Test Repository\n\nThis is a Scheme library for API validation using LLM integration.\n\nFeatures:\n- REST API validation\n- JSON schema support\n- Ollama integration\n- GitHub API client")
            (code-stats . (("test.scm" "main.scm" "api.scm") 
                          ,(let ((ht (make-hash-table)))
                             (hash-set! ht "scm" 5)
                             (hash-set! ht "md" 2)
                             (hash-set! ht "json" 1)
                             ht)))
            (git-info . ((remote . "https://github.com/user/test-repo")
                        (branch . "main")))))
         (topics (generate-topics-from-repo mock-repo-data)))
    
    (format #t "Generated topics: ~a\n" (string-join topics ", "))
    (format #t "Topic count: ~a\n" (length topics))
    (format #t "All valid: ~a\n" (every valid-github-topic? topics))))

;; Run test if executed directly
(when (equal? (basename (car (command-line))) "topic-generator.scm")
  (test-topic-generator))

(define (basename path)
  (let ((parts (string-split path #\/)))
    (if (null? parts) path (car (reverse parts)))))