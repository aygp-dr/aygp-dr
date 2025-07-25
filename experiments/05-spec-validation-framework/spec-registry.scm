#!/usr/bin/env guile
!#
;;; spec-registry.scm - Central registry for specifications

(load "validator.scm")

(use-modules (ice-9 format)
             (ice-9 hash-table)
             (srfi srfi-1))

;;; Global registry
(define *spec-registry* (make-hash-table))
(define *spec-versions* (make-hash-table))

;;; Registration functions
(define* (register-spec name spec #:key (version 1) (extends #f))
  "Register a specification with optional versioning and inheritance"
  (let* ((full-name (if (= version 1)
                       name
                       (string->symbol (format #f "~a-v~a" name version))))
         (resolved-spec (if extends
                           (merge-specs (get-spec extends) spec)
                           spec)))
    ;; Store spec
    (hash-set! *spec-registry* full-name resolved-spec)
    
    ;; Update version tracking
    (let ((versions (or (hash-ref *spec-versions* name) '())))
      (hash-set! *spec-versions* name 
                 (sort (cons version (delete version versions)) <)))
    
    ;; Update latest pointer
    (hash-set! *spec-registry* name resolved-spec)
    
    full-name))

(define* (get-spec name #:key (version #f))
  "Retrieve a specification by name and optional version"
  (if version
      (hash-ref *spec-registry* 
                (string->symbol (format #f "~a-v~a" name version)))
      (hash-ref *spec-registry* name)))

(define (list-specs)
  "List all registered specifications"
  (hash-map->list (lambda (k v) k) *spec-registry*))

(define (get-spec-versions name)
  "Get all versions of a specification"
  (or (hash-ref *spec-versions* name) '()))

;;; Spec manipulation
(define (merge-specs base-spec new-spec)
  "Merge two specifications (inheritance)"
  (cond
    ;; Both are object specs
    ((and (list? base-spec) (list? new-spec)
          (every pair? base-spec) (every pair? new-spec))
     (let ((base-alist base-spec)
           (new-alist new-spec))
       ;; New fields override base fields
       (append new-alist
               (filter (lambda (field)
                        (not (assoc (car field) new-alist)))
                      base-alist))))
    
    ;; New spec completely overrides
    (else new-spec)))

(define (compose-specs . specs)
  "Compose multiple specifications into one"
  (reduce merge-specs '() specs))

;;; Cross-spec references
(define (ref spec-name)
  "Create a reference to another spec"
  (list 'ref spec-name))

(define (resolve-refs spec)
  "Resolve all spec references recursively"
  (cond
    ((and (list? spec) (eq? (car spec) 'ref))
     (resolve-refs (get-spec (cadr spec))))
    
    ((and (list? spec) (every pair? spec))
     (map (lambda (field)
           (cons (car field) (resolve-refs (cdr field))))
          spec))
    
    ((list? spec)
     (map resolve-refs spec))
    
    (else spec)))

;;; Validation with registry
(define* (validate-with-spec data spec-name #:key (resolve #t))
  "Validate data against a registered spec"
  (let* ((spec (get-spec spec-name))
         (resolved-spec (if resolve (resolve-refs spec) spec)))
    (if spec
        (validate data resolved-spec '())
        (make-validation-result #f
          (list (make-validation-error '() spec-name #f
                  (format #f "Spec not found: ~a" spec-name)))))))

;;; Built-in specs
(define (register-common-specs)
  "Register commonly used specifications"
  
  ;; Email spec
  (register-spec 'email
    '(string-pattern "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$"))
  
  ;; URL spec
  (register-spec 'url
    '(string-pattern "^https?://[a-zA-Z0-9.-]+(/.*)?$"))
  
  ;; Timestamp spec
  (register-spec 'timestamp
    '(union integer (string-pattern "^\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}")))
  
  ;; User spec
  (register-spec 'user
    '((id . integer)
      (username . string)
      (email . (ref email))
      (created_at . (ref timestamp))
      (active . boolean)))
  
  ;; Repository spec (GitHub-like)
  (register-spec 'repository
    '((name . string)
      (description . (optional string))
      (url . (ref url))
      (owner . (ref user))
      (private . boolean)
      (stars . (integer-range 0 1000000))
      (topics . (array string 0 20))))
  
  ;; API response spec
  (register-spec 'api-response
    '((status . (enum "success" "error"))
      (data . (optional object))
      (error . (optional (object
                         (code . integer)
                         (message . string))))
      (timestamp . (ref timestamp)))))

;;; Test the registry
(define (test-registry)
  (format #t "=== Spec Registry Tests ===\n\n")
  
  ;; Register common specs
  (register-common-specs)
  
  ;; Test 1: Basic registration and retrieval
  (format #t "Test 1: Basic registration\n")
  (register-spec 'simple '((name . string) (value . number)))
  (format #t "Registered specs: ~a\n" (list-specs))
  
  ;; Test 2: Versioning
  (format #t "\nTest 2: Versioning\n")
  (register-spec 'config '((port . integer)) #:version 1)
  (register-spec 'config '((port . integer) (host . string)) #:version 2)
  (format #t "Config versions: ~a\n" (get-spec-versions 'config))
  
  ;; Test 3: Inheritance
  (format #t "\nTest 3: Inheritance\n")
  (register-spec 'base-entity '((id . integer) (created . timestamp)))
  (register-spec 'user-extended 
    '((username . string) (email . (ref email)))
    #:extends 'base-entity)
  (format #t "Extended spec: ~a\n" (get-spec 'user-extended))
  
  ;; Test 4: Validation with refs
  (format #t "\nTest 4: Validation with references\n")
  (let* ((repo-data '((name . "test-repo")
                      (url . "https://github.com/test/repo")
                      (owner . ((id . 1)
                               (username . "alice")
                               (email . "alice@example.com")
                               (created_at . "2024-01-01T00:00:00")
                               (active . #t)))
                      (private . #f)
                      (stars . 42)
                      (topics . ("scheme" "validation"))))
         (result (validate-with-spec repo-data 'repository)))
    (format #t "Repository validation: ~a\n" 
            (format-validation-result result))))

;; Helper for string->symbol
(define (string->symbol str)
  (string->symbol str))

;; Run tests if executed directly
(when (equal? (car (command-line)) "spec-registry.scm")
  (test-registry)
  (format #t "\n✓ Registry tests complete!\n"))