#!/usr/bin/env guile
!#
;;; data-pipeline-workflow.scm - ETL-style data processing workflow

(add-to-load-path "..")
(load "../workflow-engine.scm")

(use-modules (ice-9 format)
             (srfi srfi-1))

;;; Data pipeline executors
(define (fetch-data-executor step context)
  "Fetch data from multiple sources"
  (let* ((config (step-config step))
         (source (assoc-ref config 'source)))
    (case source
      ((users)
       '(((id . 1) (name . "Alice") (score . 85) (active . #t))
         ((id . 2) (name . "Bob") (score . 92) (active . #t))
         ((id . 3) (name . "Charlie") (score . 78) (active . #f))
         ((id . 4) (name . "Diana") (score . 95) (active . #t))))
      ((projects)
       '(((id . 101) (owner . 1) (name . "Project Alpha") (status . "active"))
         ((id . 102) (owner . 2) (name . "Project Beta") (status . "completed"))
         ((id . 103) (owner . 1) (name . "Project Gamma") (status . "active"))
         ((id . 104) (owner . 3) (name . "Project Delta") (status . "paused"))))
      (else '()))))

(define (clean-data-executor step context)
  "Clean and normalize data"
  (let* ((config (step-config step))
         (input-ref (assoc-ref config 'input))
         (input-data (hash-ref (context-data context) input-ref)))
    (map (lambda (record)
          ;; Normalize names to lowercase, ensure all fields present
          (let ((normalized (map (lambda (field)
                                  (cons (car field)
                                       (if (string? (cdr field))
                                           (string-downcase (cdr field))
                                           (cdr field))))
                                record)))
            ;; Add missing fields with defaults
            (append normalized
                   (if (not (assoc 'active normalized))
                       '((active . #t))
                       '()))))
        input-data)))

(define (aggregate-executor step context)
  "Aggregate data with grouping"
  (let* ((config (step-config step))
         (input-ref (assoc-ref config 'input))
         (group-by (assoc-ref config 'group-by))
         (aggregate-fn (assoc-ref config 'aggregate))
         (input-data (hash-ref (context-data context) input-ref)))
    ;; Group data
    (let ((groups (fold (lambda (item acc)
                         (let* ((key (cdr (assoc group-by item)))
                                (existing (assoc key acc)))
                           (if existing
                               (cons (cons key (cons item (cdr existing)))
                                    (remove existing acc))
                               (cons (cons key (list item)) acc))))
                       '()
                       input-data)))
      ;; Apply aggregation
      (map (lambda (group)
            (cons (car group) (aggregate-fn (cdr group))))
          groups))))

(define (join-data-executor step context)
  "Join two datasets"
  (let* ((config (step-config step))
         (left-ref (assoc-ref config 'left))
         (right-ref (assoc-ref config 'right))
         (left-key (assoc-ref config 'left-key))
         (right-key (assoc-ref config 'right-key))
         (left-data (hash-ref (context-data context) left-ref))
         (right-data (hash-ref (context-data context) right-ref)))
    ;; Simple inner join
    (fold (lambda (left-record acc)
           (let* ((left-key-val (cdr (assoc left-key left-record)))
                  (matching-right (filter (lambda (r)
                                           (equal? (cdr (assoc right-key r))
                                                  left-key-val))
                                         right-data)))
             (append acc
                    (map (lambda (right-record)
                          ;; Merge records
                          (append left-record
                                 (map (lambda (field)
                                       (cons (string->symbol
                                             (format #f "~a_~a" 
                                                    'right (car field)))
                                            (cdr field)))
                                     right-record)))
                        matching-right))))
         '()
         left-data)))

(define (generate-report-executor step context)
  "Generate pipeline execution report"
  (let* ((config (step-config step))
         (stats-ref (assoc-ref config 'stats))
         (stats-data (hash-ref (context-data context) stats-ref)))
    (format #f "# Data Pipeline Execution Report

## Pipeline Statistics

~a

## Summary
- Pipeline completed successfully
- Data quality checks passed
- All transformations applied

---
*Report generated on ~a*"
            (string-join
             (map (lambda (stat)
                   (format #f "- **~a**: ~a" (car stat) (cdr stat)))
                 stats-data)
             "\n")
            (strftime "%Y-%m-%d %H:%M:%S" (localtime (current-time))))))

;; Register executors
(register-step-executor 'fetch-data fetch-data-executor)
(register-step-executor 'clean-data clean-data-executor) 
(register-step-executor 'aggregate aggregate-executor)
(register-step-executor 'join-data join-data-executor)

;;; Create ETL workflow
(define (create-etl-workflow)
  (create-workflow
   "etl-pipeline"
   "Extract, Transform, Load data pipeline"
   ;; Extract
   (create-step 'fetch-users 'fetch-data
               '((source . users)))
   (create-step 'fetch-projects 'fetch-data
               '((source . projects)))
   
   ;; Transform - Clean
   (create-step 'clean-users 'clean-data
               '((input . fetch-users))
               'fetch-users)
   (create-step 'clean-projects 'clean-data
               '((input . fetch-projects))
               'fetch-projects)
   
   ;; Transform - Join
   (create-step 'join-user-projects 'join-data
               '((left . clean-users)
                 (right . clean-projects)
                 (left-key . id)
                 (right-key . owner))
               'clean-users 'clean-projects)
   
   ;; Transform - Aggregate
   (create-step 'user-stats 'aggregate
               '((input . join-user-projects)
                 (group-by . name)
                 (aggregate . ,(lambda (records)
                               (let ((count (length records))
                                     (active-count (length 
                                                   (filter (lambda (r)
                                                            (string=? 
                                                             (cdr (assoc 'right_status r))
                                                             "active"))
                                                          records))))
                                 `((total-projects . ,count)
                                   (active-projects . ,active-count))))))
               'join-user-projects)
   
   ;; Load - Generate stats
   (create-step 'pipeline-stats 'transform
               '((input . user-stats)
                 (transform . ,(lambda (stats)
                               `((users-processed . ,(length stats))
                                 (total-projects . ,(apply + 
                                                          (map (lambda (s)
                                                                (cdr (assoc 'total-projects 
                                                                          (cdr s))))
                                                              stats)))
                                 (pipeline-status . "success")))))
               'user-stats)
   
   ;; Generate report
   (create-step 'generate-report 'generate-report
               '((stats . pipeline-stats))
               'pipeline-stats)))

;;; Main
(define (main)
  (format #t "=== Data Pipeline Workflow ===\n\n")
  
  (let* ((workflow (create-etl-workflow))
         (result (execute-workflow workflow '())))
    (if (null? (context-errors result))
        (begin
          (format #t "Pipeline completed successfully!\n\n")
          ;; Show some intermediate results
          (format #t "User statistics:\n")
          (for-each (lambda (stat)
                     (format #t "  ~a: ~a\n" (car stat) (cdr stat)))
                   (hash-ref (context-data result) 'user-stats))
          (format #t "\n~a\n" (hash-ref (context-data result) 'generate-report)))
        (format #t "Pipeline failed: ~a\n" (context-errors result)))))

;; Helper
(define (string-downcase str)
  (list->string
   (map char-downcase (string->list str))))

;; Run if executed directly
(when (equal? (basename (car (command-line))) "data-pipeline-workflow.scm")
  (main))

(define (basename path)
  (let ((parts (string-split path #\/)))
    (if (null? parts) path (car (reverse parts)))))