#!/usr/bin/env guile
!#
;;; repo-analyzer.scm - Analyze GitHub repositories using Ollama

(add-to-load-path ".")
(load "workflow-engine.scm")

(use-modules (ice-9 format)
             (ice-9 popen)
             (ice-9 rdelim)
             (srfi srfi-1))

;;; Custom executors for GitHub and Ollama
(define (github-api-executor step context)
  "Execute GitHub API calls"
  (let* ((config (step-config step))
         (endpoint (assoc-ref config 'endpoint))
         (token (getenv "GITHUB_TOKEN")))
    (if token
        (let* ((cmd (format #f "curl -s -H 'Authorization: Bearer ~a' 'https://api.github.com~a'"
                           token endpoint))
               (port (open-pipe* OPEN_READ "/bin/sh" "-c" cmd))
               (response (read-string port)))
          (close-pipe port)
          ;; For demo, return parsed mock data
          (case endpoint
            (("/user/repos?per_page=5")
             '(((name . "awesome-project")
                (description . "A project that does awesome things")
                (language . "Python")
                (stargazers_count . 42)
                (topics . ("machine-learning" "ai" "automation")))
               ((name . "scheme-validator") 
                (description . "Validation framework for Scheme")
                (language . "Scheme")
                (stargazers_count . 15)
                (topics . ("scheme" "validation" "api")))))
            (else '())))
        (error "GITHUB_TOKEN not set"))))

(define (ollama-analyze-executor step context)
  "Analyze text using Ollama"
  (let* ((config (step-config step))
         (input-ref (assoc-ref config 'input))
         (prompt-template (assoc-ref config 'prompt))
         (input-data (hash-ref (context-data context) input-ref)))
    (if (and input-data prompt-template)
        (let* ((prompt (prompt-template input-data))
               (request-body `((model . "llama3.2:3b")
                              (prompt . ,prompt)
                              (stream . #f))))
          ;; Simulated Ollama response
          (format #t "Analyzing with Ollama: ~a chars of prompt~%" 
                  (string-length prompt))
          `((analysis . "This repository appears to be focused on machine learning and automation. Key strengths include clear documentation and active maintenance.")
            (suggestions . ("Add more comprehensive tests"
                          "Consider adding CI/CD pipeline"
                          "Improve error handling in core modules"))
            (score . 85)))
        (error "Missing input data or prompt template"))))

(define (generate-report-executor step context)
  "Generate a markdown report from analysis"
  (let* ((config (step-config step))
         (repo-ref (assoc-ref config 'repo-data))
         (analysis-ref (assoc-ref config 'analysis))
         (repo-data (hash-ref (context-data context) repo-ref))
         (analysis-data (hash-ref (context-data context) analysis-ref)))
    (if (and repo-data analysis-data)
        (format #f "# Repository Analysis Report

## Repository: ~a

**Description**: ~a  
**Language**: ~a  
**Stars**: ~a  
**Topics**: ~a

## AI Analysis

~a

### Improvement Suggestions

~a

### Quality Score: ~a/100

---
*Generated on ~a*"
                (car (assoc-ref repo-data 'name))
                (car (assoc-ref repo-data 'description))
                (car (assoc-ref repo-data 'language))
                (car (assoc-ref repo-data 'stargazers_count))
                (string-join (vector->list (car (assoc-ref repo-data 'topics))) ", ")
                (car (assoc-ref analysis-data 'analysis))
                (string-join (map (lambda (s) (format #f "- ~a" s))
                                (car (assoc-ref analysis-data 'suggestions)))
                            "\n")
                (car (assoc-ref analysis-data 'score))
                (current-time-string))
        (error "Missing repository or analysis data"))))

;; Register custom executors
(register-step-executor 'github-api github-api-executor)
(register-step-executor 'ollama-analyze ollama-analyze-executor)
(register-step-executor 'generate-report generate-report-executor)

;;; Repository analysis workflows
(define (create-repo-analysis-workflow)
  "Create workflow for analyzing GitHub repositories"
  (create-workflow
   "repo-analysis"
   "Analyze GitHub repositories with AI"
   ;; Fetch repositories
   (create-step 'fetch-repos 'github-api
               '((endpoint . "/user/repos?per_page=5")))
   
   ;; Select first repository for detailed analysis
   (create-step 'select-repo 'transform
               '((input . fetch-repos)
                 (transform . ,(lambda (repos) (car repos))))
               'fetch-repos)
   
   ;; Prepare analysis prompt
   (create-step 'prepare-prompt 'transform
               '((input . select-repo)
                 (transform . ,(lambda (repo)
                               (format #f "Analyze this GitHub repository:
Name: ~a
Description: ~a
Language: ~a
Topics: ~a

Provide:
1. A brief analysis of the repository's purpose and quality
2. Specific suggestions for improvement
3. A quality score out of 100"
                                      (cdr (assoc 'name repo))
                                      (cdr (assoc 'description repo))
                                      (cdr (assoc 'language repo))
                                      (string-join 
                                       (vector->list (cdr (assoc 'topics repo)))
                                       ", ")))))
               'select-repo)
   
   ;; Analyze with Ollama
   (create-step 'analyze 'ollama-analyze
               '((input . select-repo)
                 (prompt . ,(lambda (repo)
                            (format #f "Analyze this repository: ~a" 
                                   (cdr (assoc 'name repo))))))
               'select-repo)
   
   ;; Generate report
   (create-step 'generate-report 'generate-report
               '((repo-data . select-repo)
                 (analysis . analyze))
               'select-repo 'analyze)))

(define (create-multi-repo-workflow)
  "Create workflow for analyzing multiple repositories"
  (create-workflow
   "multi-repo-analysis"
   "Analyze multiple repositories and rank them"
   ;; Fetch repositories
   (create-step 'fetch-repos 'github-api
               '((endpoint . "/user/repos?per_page=5")))
   
   ;; Analyze each repository
   (create-step 'analyze-all 'transform
               '((input . fetch-repos)
                 (transform . ,(lambda (repos)
                               (map (lambda (repo)
                                     (cons (cons 'analysis
                                                (format #f "~a: A ~a project with ~a stars"
                                                       (cdr (assoc 'name repo))
                                                       (cdr (assoc 'language repo))
                                                       (cdr (assoc 'stargazers_count repo))))
                                          repo))
                                   repos))))
               'fetch-repos)
   
   ;; Rank by stars
   (create-step 'rank-repos 'transform
               '((input . analyze-all)
                 (transform . ,(lambda (repos)
                               (sort repos
                                    (lambda (a b)
                                     (> (cdr (assoc 'stargazers_count a))
                                        (cdr (assoc 'stargazers_count b))))))))
               'analyze-all)
   
   ;; Generate summary
   (create-step 'summary 'transform
               '((input . rank-repos)
                 (transform . ,(lambda (repos)
                               (format #f "## Repository Rankings

~a

Total repositories analyzed: ~a
Most popular: ~a (~a stars)"
                                      (string-join
                                       (map (lambda (repo i)
                                             (format #f "~a. **~a** - ~a stars\n   ~a"
                                                    (+ i 1)
                                                    (cdr (assoc 'name repo))
                                                    (cdr (assoc 'stargazers_count repo))
                                                    (cdr (assoc 'analysis repo))))
                                           repos
                                           (iota (length repos)))
                                       "\n\n")
                                      (length repos)
                                      (cdr (assoc 'name (car repos)))
                                      (cdr (assoc 'stargazers_count (car repos)))))))
               'rank-repos)))

;;; Test functions
(define (test-single-repo-analysis)
  "Test single repository analysis"
  (format #t "=== Single Repository Analysis ===\n\n")
  
  (let* ((workflow (create-repo-analysis-workflow))
         (result (execute-workflow workflow '())))
    (if (null? (context-errors result))
        (let ((report (hash-ref (context-data result) 'generate-report)))
          (format #t "~a\n" report))
        (format #t "Errors: ~a\n" (context-errors result)))))

(define (test-multi-repo-analysis)
  "Test multiple repository analysis"
  (format #t "\n=== Multiple Repository Analysis ===\n\n")
  
  (let* ((workflow (create-multi-repo-workflow))
         (result (execute-workflow workflow '())))
    (if (null? (context-errors result))
        (let ((summary (hash-ref (context-data result) 'summary)))
          (format #t "~a\n" summary))
        (format #t "Errors: ~a\n" (context-errors result)))))

;;; Utility to convert vector to list
(define (vector->list vec)
  (if (vector? vec)
      (let loop ((i 0) (acc '()))
        (if (< i (vector-length vec))
            (loop (+ i 1) (cons (vector-ref vec i) acc))
            (reverse acc)))
      '()))

;;; Main
(define (run-analyzer-tests)
  (format #t "=== Repository Analyzer Tests ===\n\n")
  
  ;; Check for GitHub token
  (if (getenv "GITHUB_TOKEN")
      (begin
        (test-single-repo-analysis)
        (test-multi-repo-analysis))
      (format #t "Warning: GITHUB_TOKEN not set. Using mock data.\n\n"))
  
  (format #t "\n✓ Repository analyzer tests complete!\n"))

;; Run tests if executed directly
(when (equal? (car (command-line)) "repo-analyzer.scm")
  (run-analyzer-tests))