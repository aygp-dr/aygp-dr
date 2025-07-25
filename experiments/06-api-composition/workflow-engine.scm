#!/usr/bin/env guile
!#
;;; workflow-engine.scm - Compose API calls into workflows with validation

(add-to-load-path "../05-spec-validation-framework")
(add-to-load-path "../04-github-api-integration")

(load "../05-spec-validation-framework/validator.scm")
(load "../05-spec-validation-framework/spec-registry.scm")

(use-modules (ice-9 format)
             (ice-9 match)
             (ice-9 hash-table)
             (srfi srfi-1)
             (srfi srfi-9))

;;; Workflow step definition
(define-record-type <workflow-step>
  (make-workflow-step id type config dependencies)
  workflow-step?
  (id step-id)
  (type step-type)
  (config step-config)
  (dependencies step-dependencies))

;;; Workflow definition
(define-record-type <workflow>
  (make-workflow name description steps)
  workflow?
  (name workflow-name)
  (description workflow-description)
  (steps workflow-steps))

;;; Execution context
(define-record-type <execution-context>
  (make-execution-context data errors log)
  execution-context?
  (data context-data context-data-set!)
  (errors context-errors context-errors-set!)
  (log context-log context-log-set!))

;;; Step executors registry
(define *step-executors* (make-hash-table))

(define (register-step-executor type executor-fn)
  "Register a step executor function"
  (hash-set! *step-executors* type executor-fn))

;;; Core workflow execution
(define (execute-workflow workflow initial-data)
  "Execute a workflow with initial data"
  (let ((context (make-execution-context 
                  (make-hash-table) '() '())))
    ;; Set initial data
    (hash-set! (context-data context) 'input initial-data)
    
    ;; Execute steps in dependency order
    (let ((ordered-steps (topological-sort (workflow-steps workflow))))
      (for-each (lambda (step)
                  (execute-step step context))
                ordered-steps))
    
    context))

(define (execute-step step context)
  "Execute a single workflow step"
  (let ((executor (hash-ref *step-executors* (step-type step))))
    (if executor
        (catch #t
          (lambda ()
            (log-message context (format #f "Executing step: ~a" (step-id step)))
            (let ((result (executor step context)))
              (hash-set! (context-data context) (step-id step) result)
              (log-message context (format #f "Step ~a completed" (step-id step)))))
          (lambda (key . args)
            (let ((error-msg (format #f "Step ~a failed: ~a" (step-id step) args)))
              (log-message context error-msg)
              (context-errors-set! context 
                (cons error-msg (context-errors context))))))
        (let ((error-msg (format #f "No executor for step type: ~a" (step-type step))))
          (log-message context error-msg)
          (context-errors-set! context 
            (cons error-msg (context-errors context)))))))

(define (log-message context message)
  "Add a message to the context log"
  (context-log-set! context 
    (cons (cons (current-time-string) message) 
          (context-log context))))

;;; Dependency resolution
(define (topological-sort steps)
  "Sort steps by dependencies"
  (let ((visited (make-hash-table))
        (result '()))
    (define (visit step)
      (unless (hash-ref visited (step-id step))
        (hash-set! visited (step-id step) #t)
        ;; Visit dependencies first
        (for-each (lambda (dep-id)
                    (let ((dep-step (find (lambda (s) 
                                           (eq? (step-id s) dep-id))
                                         steps)))
                      (when dep-step (visit dep-step))))
                  (step-dependencies step))
        (set! result (cons step result))))
    
    (for-each visit steps)
    (reverse result)))

;;; Built-in step executors
(define (transform-executor step context)
  "Transform data using a function"
  (let* ((config (step-config step))
         (input-ref (assoc-ref config 'input))
         (transform-fn (assoc-ref config 'transform))
         (input-data (hash-ref (context-data context) input-ref)))
    (if (and input-data transform-fn)
        (transform-fn input-data)
        (error "Missing input or transform function"))))

(define (validate-executor step context)
  "Validate data against a spec"
  (let* ((config (step-config step))
         (input-ref (assoc-ref config 'input))
         (spec-name (assoc-ref config 'spec))
         (input-data (hash-ref (context-data context) input-ref)))
    (if (and input-data spec-name)
        (let ((result (validate-with-spec input-data spec-name)))
          (if (validation-valid? result)
              input-data
              (error "Validation failed" (validation-errors result))))
        (error "Missing input or spec"))))

(define (merge-executor step context)
  "Merge multiple data sources"
  (let* ((config (step-config step))
         (inputs (assoc-ref config 'inputs))
         (merge-fn (or (assoc-ref config 'merge-fn) append)))
    (if inputs
        (let ((input-values (map (lambda (ref)
                                  (hash-ref (context-data context) ref))
                                inputs)))
          (apply merge-fn input-values))
        (error "No inputs specified for merge"))))

(define (filter-executor step context)
  "Filter data based on predicate"
  (let* ((config (step-config step))
         (input-ref (assoc-ref config 'input))
         (predicate (assoc-ref config 'predicate))
         (input-data (hash-ref (context-data context) input-ref)))
    (if (and input-data predicate)
        (filter predicate input-data)
        (error "Missing input or predicate"))))

(define (api-call-executor step context)
  "Make an API call (simulated)"
  (let* ((config (step-config step))
         (endpoint (assoc-ref config 'endpoint))
         (method (or (assoc-ref config 'method) 'GET))
         (input-ref (assoc-ref config 'input))
         (input-data (when input-ref 
                       (hash-ref (context-data context) input-ref))))
    (format #t "Simulating ~a request to ~a~%" method endpoint)
    ;; In real implementation, this would make actual HTTP requests
    ;; For now, return mock data
    (case endpoint
      (("/user") '((login . "testuser") (id . 12345)))
      (("/repos") '(((name . "repo1") (stars . 10))
                   ((name . "repo2") (stars . 20))))
      (else '((status . "ok"))))))

;;; Register built-in executors
(register-step-executor 'transform transform-executor)
(register-step-executor 'validate validate-executor)
(register-step-executor 'merge merge-executor)
(register-step-executor 'filter filter-executor)
(register-step-executor 'api-call api-call-executor)

;;; Workflow builder helpers
(define (create-workflow name description . steps)
  "Create a workflow with the given steps"
  (make-workflow name description steps))

(define (create-step id type config . deps)
  "Create a workflow step"
  (make-workflow-step id type config deps))

;;; Example workflows
(define (test-simple-workflow)
  "Test a simple transformation workflow"
  (format #t "=== Simple Workflow Test ===\n\n")
  
  (let* ((workflow 
          (create-workflow 
           "simple-transform"
           "Transform and validate data"
           (create-step 'fetch 'api-call 
                       '((endpoint . "/repos")))
           (create-step 'transform 'transform
                       `((input . fetch)
                         (transform . ,(lambda (repos)
                                        (map (lambda (repo)
                                              (cons (cons 'starred 
                                                         (> (cdr (assoc 'stars repo)) 15))
                                                   repo))
                                            repos))))
                       'fetch)
           (create-step 'filter-starred 'filter
                       `((input . transform)
                         (predicate . ,(lambda (repo)
                                        (cdr (assoc 'starred repo)))))
                       'transform)))
         (result (execute-workflow workflow '())))
    
    (format #t "Workflow: ~a\n" (workflow-name workflow))
    (format #t "Final result: ~a\n" 
            (hash-ref (context-data result) 'filter-starred))
    (format #t "Errors: ~a\n" (context-errors result))
    (format #t "Log entries: ~a\n\n" (length (context-log result)))))

(define (test-validation-workflow)
  "Test workflow with validation"
  (format #t "=== Validation Workflow Test ===\n\n")
  
  ;; Register a test spec
  (register-spec 'test-user
    '((login . string)
      (id . integer)))
  
  (let* ((workflow
          (create-workflow
           "validate-user"
           "Fetch and validate user data"
           (create-step 'fetch-user 'api-call
                       '((endpoint . "/user")))
           (create-step 'validate-user 'validate
                       '((input . fetch-user)
                         (spec . test-user))
                       'fetch-user)))
         (result (execute-workflow workflow '())))
    
    (format #t "Workflow: ~a\n" (workflow-name workflow))
    (format #t "Validated data: ~a\n" 
            (hash-ref (context-data result) 'validate-user))
    (format #t "Valid: ~a\n\n" (null? (context-errors result)))))

(define (test-complex-workflow)
  "Test complex workflow with multiple branches"
  (format #t "=== Complex Workflow Test ===\n\n")
  
  (let* ((workflow
          (create-workflow
           "complex-analysis"
           "Fetch from multiple sources and analyze"
           ;; Parallel fetches
           (create-step 'fetch-user 'api-call
                       '((endpoint . "/user")))
           (create-step 'fetch-repos 'api-call
                       '((endpoint . "/repos")))
           ;; Transform repos
           (create-step 'enrich-repos 'transform
                       `((input . fetch-repos)
                         (transform . ,(lambda (repos)
                                        (let loop ((rs repos) (i 0) (acc '()))
                                          (if (null? rs)
                                              (reverse acc)
                                              (loop (cdr rs) (+ i 1)
                                                   (cons (cons (cons 'index i) 
                                                              (car rs))
                                                        acc)))))))
                       'fetch-repos)
           ;; Merge results
           (create-step 'merge-data 'merge
                       `((inputs . (fetch-user enrich-repos))
                         (merge-fn . ,(lambda (user repos)
                                       (list (cons 'user user)
                                            (cons 'repos repos)))))
                       'fetch-user 'enrich-repos)))
         (result (execute-workflow workflow '())))
    
    (format #t "Workflow: ~a\n" (workflow-name workflow))
    (format #t "Merged result: ~a\n" 
            (hash-ref (context-data result) 'merge-data))
    (format #t "Execution log:\n")
    (for-each (lambda (entry)
               (format #t "  [~a] ~a\n" (car entry) (cdr entry)))
             (reverse (context-log result)))))

;;; Utilities
(define (current-time-string)
  "Get current time as string"
  (strftime "%Y-%m-%d %H:%M:%S" (localtime (current-time))))

(define (assoc-ref alist key)
  "Get value from association list"
  (let ((pair (assoc key alist)))
    (if pair (cdr pair) #f)))

(define (iota n)
  "Generate list of integers from 0 to n-1"
  (let loop ((i 0) (acc '()))
    (if (>= i n)
        (reverse acc)
        (loop (+ i 1) (cons i acc)))))

;;; Main test runner
(define (run-tests)
  (format #t "=== Workflow Engine Tests ===\n\n")
  (test-simple-workflow)
  (test-validation-workflow)
  (test-complex-workflow)
  (format #t "\n✓ Workflow engine tests complete!\n"))

;; Run tests if executed directly
(when (equal? (car (command-line)) "workflow-engine.scm")
  (run-tests))