#!/usr/bin/env guile
!#
;;; simulator.scm - Simulate the complete repo topic generation flow

(add-to-load-path "../05-spec-validation-framework")
(add-to-load-path "../06-api-composition")

(load "../05-spec-validation-framework/validator.scm")
(load "../05-spec-validation-framework/spec-registry.scm")
(load "github-client-v2.scm")
(load "topic-generator.scm")

(use-modules (ice-9 format)
             (ice-9 popen)
             (ice-9 rdelim)
             (ice-9 ftw)
             (ice-9 regex)
             (srfi srfi-1))

;;; ANSI colors for output
(define *green* "\x1b[0;32m")
(define *blue* "\x1b[0;34m")
(define *yellow* "\x1b[0;33m")
(define *red* "\x1b[0;31m")
(define *reset* "\x1b[0m")

(define (step-header title)
  (format #t "~%~a=== ~a ===~a~%" *blue* title *reset*))

(define (step-info msg . args)
  (apply format #t (string-append "~a✓~a " msg "~%") 
         *green* *reset* args))

(define (step-warn msg . args)
  (apply format #t (string-append "~a⚠~a " msg "~%") 
         *yellow* *reset* args))

(define (step-error msg . args)
  (apply format #t (string-append "~a✗~a " msg "~%") 
         *red* *reset* args))

;;; Repository analysis
(define (analyze-current-repo)
  "Analyze the current repository structure"
  (step-header "Repository Analysis")
  
  ;; Get repo info
  (let* ((repo-path (get-repo-root))
         (readme-content (read-readme-file repo-path))
         (code-stats (analyze-code-structure repo-path))
         (git-info (get-git-info repo-path)))
    
    (step-info "Repository path: ~a" repo-path)
    (step-info "README size: ~a characters" (string-length readme-content))
    (step-info "Code files found: ~a" (length (car code-stats)))
    (step-info "Primary language: ~a" (get-primary-language code-stats))
    
    `((path . ,repo-path)
      (readme . ,readme-content)
      (code-stats . ,code-stats)
      (git-info . ,git-info))))

(define (get-repo-root)
  "Get repository root directory"
  (let* ((port (open-pipe* OPEN_READ "git" "rev-parse" "--show-toplevel"))
         (path (read-line port)))
    (close-pipe port)
    (if (eof-object? path)
        (getcwd)
        (string-trim-right path))))

(define (read-readme-file repo-path)
  "Read README file content"
  (let ((readme-files '("README.md" "readme.md" "README.rst" "README.txt")))
    (or (any (lambda (file)
              (let ((full-path (string-append repo-path "/" file)))
                (if (file-exists? full-path)
                    (call-with-input-file full-path read-string)
                    #f)))
             readme-files)
        "No README found")))

(define (analyze-code-structure repo-path)
  "Analyze code files in repository"
  (let ((files '())
        (extensions (make-hash-table)))
    
    ;; Walk the directory tree
    (file-system-fold
     (lambda (name stat result) ; enter?
       (not (member (basename name) '(".git" "node_modules" ".cache"))))
     (lambda (name stat result) ; leaf
       (let ((ext (get-file-extension name)))
         (when ext
           (hash-set! extensions ext 
                     (+ 1 (or (hash-ref extensions ext) 0)))
           (set! files (cons name files))))
       result)
     (lambda (name stat result) result) ; down
     (lambda (name stat result) result) ; up
     (lambda (name stat result) result) ; skip
     (lambda (name stat errno result) result) ; error
     #f
     repo-path)
    
    (list files extensions)))

(define (get-file-extension filename)
  "Get file extension"
  (let ((dot-pos (string-index-right filename #\.)))
    (if dot-pos
        (substring filename (+ dot-pos 1))
        #f)))

(define (get-primary-language code-stats)
  "Determine primary programming language"
  (let* ((extensions (cadr code-stats))
         (counts (hash-fold (lambda (k v acc) (cons (cons k v) acc)) '() extensions))
         (sorted (sort counts (lambda (a b) (> (cdr a) (cdr b))))))
    (if (null? sorted)
        "unknown"
        (extension->language (caar sorted)))))

(define (extension->language ext)
  "Map file extension to language"
  (case (string->symbol ext)
    ((scm scheme lisp) "scheme")
    ((py) "python")
    ((js mjs) "javascript")
    ((ts) "typescript")
    ((rs) "rust")
    ((go) "go")
    ((c) "c")
    ((cpp cc cxx) "cpp")
    ((java) "java")
    ((md) "markdown")
    ((json) "json")
    ((yml yaml) "yaml")
    ((sh) "shell")
    (else ext)))

(define (get-git-info repo-path)
  "Get git repository information"
  (let* ((remote-port (open-pipe* OPEN_READ "git" "remote" "get-url" "origin"))
         (remote-url (read-line remote-port))
         (branch-port (open-pipe* OPEN_READ "git" "branch" "--show-current"))
         (branch (read-line branch-port)))
    (close-pipe remote-port)
    (close-pipe branch-port)
    `((remote . ,(if (eof-object? remote-url) "unknown" remote-url))
      (branch . ,(if (eof-object? branch) "main" branch)))))

;;; Simulation of topic generation
(define (simulate-topic-generation repo-data)
  "Simulate the complete topic generation flow"
  (step-header "Topic Generation Simulation")
  
  ;; Extract repository information
  (let* ((readme (assoc-ref repo-data 'readme))
         (code-stats (assoc-ref repo-data 'code-stats))
         (primary-lang (get-primary-language code-stats))
         (git-info (assoc-ref repo-data 'git-info)))
    
    (step-info "Analyzing repository content...")
    (step-info "Primary language: ~a" primary-lang)
    (step-info "README content: ~a chars" (string-length readme))
    
    ;; Simulate Ollama analysis
    (let ((analysis-prompt (build-analysis-prompt readme primary-lang code-stats)))
      (step-info "Built analysis prompt (~a characters)" (string-length analysis-prompt))
      
      ;; Simulate the LLM response based on our repository
      (let ((simulated-topics (simulate-llm-response repo-data)))
        (step-info "Generated topics: ~a" (string-join simulated-topics ", "))
        
        ;; Validate topics
        (let ((validated-topics (validate-topics simulated-topics)))
          (step-info "Validated topics: ~a" (string-join validated-topics ", "))
          validated-topics)))))

(define (build-analysis-prompt readme primary-lang code-stats)
  "Build prompt for topic generation"
  (let* ((files (car code-stats))
         (extensions (cadr code-stats))
         (file-types (hash-fold (lambda (k v acc) 
                                 (cons (format #f "~a (~a)" k v) acc)) 
                               '() extensions)))
    (format #f "Analyze this repository and suggest relevant GitHub topics.

Primary Language: ~a
File Types: ~a

README Content:
~a

Generate 5-10 specific, relevant GitHub topics that describe:
- The main programming language(s)
- The purpose/domain of the project  
- Key technologies or frameworks used
- The type of project (library, tool, api, etc)

Topics should be lowercase, use hyphens not spaces, and be recognizable GitHub topics."
            primary-lang
            (string-join file-types ", ")
            (if (> (string-length readme) 2000)
                (string-append (substring readme 0 2000) "...")
                readme))))

(define (simulate-llm-response repo-data)
  "Simulate LLM response based on repository analysis"
  (let* ((code-stats (assoc-ref repo-data 'code-stats))
         (primary-lang (get-primary-language code-stats))
         (files (car code-stats))
         (readme (assoc-ref repo-data 'readme)))
    
    ;; Base topics from language detection
    (let ((topics (list primary-lang)))
      
      ;; Add topics based on file analysis
      (when (any (lambda (f) (string-contains f "ollama")) files)
        (set! topics (cons "ollama" topics)))
      
      (when (any (lambda (f) (string-contains f "github")) files)
        (set! topics (cons "github-api" topics)))
      
      (when (any (lambda (f) (string-contains f "workflow")) files)
        (set! topics (cons "workflow" topics)))
      
      (when (any (lambda (f) (string-contains f "validation")) files)
        (set! topics (cons "validation" topics)))
      
      (when (any (lambda (f) (string-contains f "spec")) files)
        (set! topics (cons "specification" topics)))
      
      ;; Add topics based on README content
      (when (string-contains (string-downcase readme) "experiment")
        (set! topics (cons "experiments" topics)))
      
      (when (string-contains (string-downcase readme) "llm")
        (set! topics (cons "llm" topics)))
      
      (when (string-contains (string-downcase readme) "api")
        (set! topics (cons "api" topics)))
      
      ;; Remove duplicates and return
      (delete-duplicates topics))))

(define (string-contains str substr)
  "Check if string contains substring"
  (string-match substr str))

(define (validate-topics topics)
  "Validate and filter topics for GitHub"
  (filter (lambda (topic)
           (and (string? topic)
                (> (string-length topic) 0)
                (<= (string-length topic) 50)
                (string-match "^[a-z0-9][a-z0-9-]*[a-z0-9]?$" topic)))
         (take topics (min (length topics) 20))))

;;; Simulate GitHub update
(define (simulate-github-update topics dry-run?)
  "Simulate updating GitHub repository topics"
  (step-header "GitHub Update Simulation")
  
  (if dry-run?
      (begin
        (step-info "DRY RUN: Would update repository with topics:")
        (for-each (lambda (topic)
                   (format #t "  - ~a~%" topic))
                 topics)
        (step-info "No actual changes made"))
      (begin
        (step-warn "LIVE UPDATE: This would update GitHub repository")
        (step-info "Topics to set: ~a" (string-join topics ", "))
        (step-warn "GitHub API call would be made here")))
  
  #t)

;;; Main simulation
(define (run-simulation)
  "Run the complete topic generation simulation"
  (format #t "~a=== Repository Topic Generation Simulation ===~a~%~%" 
          *blue* *reset*)
  
  ;; Step 1: Analyze repository
  (let ((repo-data (analyze-current-repo)))
    
    ;; Step 2: Generate topics
    (let ((topics (simulate-topic-generation repo-data)))
      
      ;; Step 3: Simulate GitHub update  
      (simulate-github-update topics #t)
      
      ;; Summary
      (step-header "Simulation Summary")
      (step-info "Repository analyzed successfully")
      (step-info "Generated ~a topics: ~a" 
                (length topics) (string-join topics ", "))
      (step-info "Topics validated for GitHub requirements")
      (step-info "Simulation completed successfully")
      
      ;; Return results
      `((success . #t)
        (topics . ,topics)
        (repo-data . ,repo-data)))))

;;; Utilities
(define (string-trim-right str)
  "Remove trailing whitespace"
  (let ((len (string-length str)))
    (if (= len 0)
        str
        (let loop ((i (- len 1)))
          (cond
            ((< i 0) "")
            ((char-whitespace? (string-ref str i))
             (loop (- i 1)))
            (else (substring str 0 (+ i 1))))))))

(define (string-downcase str)
  "Convert string to lowercase"
  (list->string (map char-downcase (string->list str))))

;; Run simulation if executed directly
(when (equal? (basename (car (command-line))) "simulator.scm")
  (run-simulation))

(define (basename path)
  (let ((parts (string-split path #\/)))
    (if (null? parts) path (car (reverse parts)))))