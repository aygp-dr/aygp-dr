#!/usr/bin/env guile
!#
;;; code-review-workflow.scm - Automated code review workflow

(add-to-load-path "..")
(load "../workflow-engine.scm")

(use-modules (ice-9 format))

;;; Code review specific executors
(define (extract-code-executor step context)
  "Extract code snippets from repository"
  (let* ((config (step-config step))
         (repo-ref (assoc-ref config 'repo))
         (repo-data (hash-ref (context-data context) repo-ref)))
    ;; Simulated code extraction
    `((files . (((path . "src/main.scm")
                (language . "scheme")
                (content . "(define (factorial n)
  (if (<= n 1)
      1
      (* n (factorial (- n 1)))))")
                (lines . 5))
               ((path . "tests/test-main.scm")
                (language . "scheme")
                (content . "(test-equal \"factorial of 5\" 120 (factorial 5))")
                (lines . 1))))
      (total-lines . 6)
      (languages . ("scheme")))))

(define (analyze-code-quality-executor step context)
  "Analyze code quality metrics"
  (let* ((config (step-config step))
         (code-ref (assoc-ref config 'code))
         (code-data (hash-ref (context-data context) code-ref)))
    `((metrics . ((complexity . "low")
                 (test-coverage . "partial")
                 (documentation . "minimal")))
      (issues . (((severity . "warning")
                 (file . "src/main.scm")
                 (message . "Missing function documentation"))
                ((severity . "info")
                 (file . "src/main.scm")
                 (message . "Consider using tail recursion"))))
      (score . 75))))

(define (generate-review-executor step context)
  "Generate code review report"
  (let* ((config (step-config step))
         (quality-ref (assoc-ref config 'quality))
         (quality-data (hash-ref (context-data context) quality-ref)))
    (format #f "# Automated Code Review

## Quality Metrics
- Complexity: ~a
- Test Coverage: ~a  
- Documentation: ~a

## Issues Found

~a

## Overall Score: ~a/100

### Recommendations
1. Add comprehensive documentation
2. Improve test coverage
3. Consider performance optimizations

---
*Review generated on ~a*"
            (cdr (assoc 'complexity (cdr (assoc 'metrics quality-data))))
            (cdr (assoc 'test-coverage (cdr (assoc 'metrics quality-data))))
            (cdr (assoc 'documentation (cdr (assoc 'metrics quality-data))))
            (string-join
             (map (lambda (issue)
                   (format #f "- **~a** (~a): ~a"
                          (cdr (assoc 'severity issue))
                          (cdr (assoc 'file issue))
                          (cdr (assoc 'message issue))))
                  (cdr (assoc 'issues quality-data)))
             "\n")
            (cdr (assoc 'score quality-data))
            (strftime "%Y-%m-%d %H:%M:%S" (localtime (current-time))))))

;; Register executors
(register-step-executor 'extract-code extract-code-executor)
(register-step-executor 'analyze-code-quality analyze-code-quality-executor)
(register-step-executor 'generate-review generate-review-executor)

;;; Create code review workflow
(define (create-code-review-workflow)
  (create-workflow
   "code-review"
   "Automated code review with quality analysis"
   ;; Mock repository data
   (create-step 'mock-repo 'transform
               '((input . input)
                 (transform . ,(lambda (data)
                               '((name . "example-project")
                                 (language . "Scheme"))))))
   
   ;; Extract code
   (create-step 'extract-code 'extract-code
               '((repo . mock-repo))
               'mock-repo)
   
   ;; Analyze quality
   (create-step 'analyze-quality 'analyze-code-quality
               '((code . extract-code))
               'extract-code)
   
   ;; Generate review
   (create-step 'generate-review 'generate-review
               '((quality . analyze-quality))
               'analyze-quality)))

;;; Run the workflow
(define (main)
  (format #t "=== Code Review Workflow ===\n\n")
  
  (let* ((workflow (create-code-review-workflow))
         (result (execute-workflow workflow '())))
    (if (null? (context-errors result))
        (format #t "~a\n" (hash-ref (context-data result) 'generate-review))
        (format #t "Workflow failed: ~a\n" (context-errors result)))))

;; Run if executed directly
(when (equal? (basename (car (command-line))) "code-review-workflow.scm")
  (main))

;; Helper for basename
(define (basename path)
  (let ((parts (string-split path #\/)))
    (if (null? parts) path (car (reverse parts)))))