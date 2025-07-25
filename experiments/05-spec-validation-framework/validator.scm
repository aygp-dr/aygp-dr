#!/usr/bin/env guile
!#
;;; validator.scm - Core validation engine for Scheme specifications

(use-modules (ice-9 format)
             (ice-9 match)
             (ice-9 regex)
             (srfi srfi-1)
             (srfi srfi-9))  ; For define-record-type

;;; Validation result structure
(define-record-type <validation-result>
  (make-validation-result valid? errors)
  validation-result?
  (valid? validation-valid?)
  (errors validation-errors))

;;; Error structure
(define-record-type <validation-error>
  (make-validation-error path expected actual message)
  validation-error?
  (path error-path)
  (expected error-expected)
  (actual error-actual)
  (message error-message))

;;; Main validation function
(define* (validate data spec #:optional (path '()))
  "Validate data against a specification"
  (cond
    ;; Direct type specs
    ((symbol? spec)
     (validate-type data spec path))
    
    ;; Object specs (association list)
    ((and (list? spec) (every pair? spec))
     (validate-object data spec path))
    
    ;; Complex type expressions
    ((list? spec)
     (match spec
       (('array item-spec . constraints)
        (validate-array data item-spec constraints path))
       (('optional inner-spec)
        (if data
            (validate data inner-spec path)
            (make-validation-result #t '())))
       (('union . type-specs)
        (validate-union data type-specs path))
       (('enum . values)
        (validate-enum data values path))
       (('string-pattern pattern)
        (validate-string-pattern data pattern path))
       (('number-range min max)
        (validate-number-range data min max path))
       (('integer-range min max)
        (validate-integer-range data min max path))
       (('object . nested-spec)
        (validate-object data nested-spec path))
       (_ (make-validation-result #f 
            (list (make-validation-error path spec data 
                    "Unknown spec type"))))))
    
    ;; Unknown spec
    (else
     (make-validation-result #f 
       (list (make-validation-error path spec data 
               "Invalid specification format"))))))

;;; Type validators
(define (validate-type data type path)
  "Validate basic types"
  (let ((valid? (case type
                  ((string) (string? data))
                  ((number) (number? data))
                  ((integer) (and (number? data) (integer? data)))
                  ((boolean) (boolean? data))
                  ((null) (null? data))
                  (else #f))))
    (if valid?
        (make-validation-result #t '())
        (make-validation-result #f
          (list (make-validation-error path type (type-of data)
                  (format #f "Expected ~a, got ~a" type (type-of data))))))))

(define (type-of data)
  "Get the type of data"
  (cond
    ((string? data) 'string)
    ((integer? data) 'integer)
    ((number? data) 'number)
    ((boolean? data) 'boolean)
    ((null? data) 'null)
    ((list? data) 'list)
    ((pair? data) 'pair)
    (else 'unknown)))

;;; Object validation
(define (validate-object data spec path)
  "Validate object against spec"
  (if (not (and (list? data) (every pair? data)))
      (make-validation-result #f
        (list (make-validation-error path 'object (type-of data)
                "Expected object (association list)")))
      (let ((results (map (lambda (field-spec)
                           (let* ((field-name (car field-spec))
                                  (field-type (cdr field-spec))
                                  (field-value (assoc-ref data field-name))
                                  (field-path (append path (list field-name))))
                             (if (and (not field-value)
                                      (not (optional-field? field-type)))
                                 (make-validation-result #f
                                   (list (make-validation-error field-path
                                           field-type 'missing
                                           "Required field missing")))
                                 (validate field-value field-type field-path))))
                         spec)))
        (combine-results results))))

(define (optional-field? spec)
  "Check if field is optional"
  (and (list? spec) (eq? (car spec) 'optional)))

;;; Array validation
(define (validate-array data item-spec constraints path)
  "Validate array with optional min/max constraints"
  (if (not (list? data))
      (make-validation-result #f
        (list (make-validation-error path 'array (type-of data)
                "Expected array")))
      (let* ((length (length data))
             (min-items (if (pair? constraints) (car constraints) #f))
             (max-items (if (and (pair? constraints) (pair? (cdr constraints)))
                           (cadr constraints) #f))
             (length-errors
              (append
               (if (and min-items (< length min-items))
                   (list (make-validation-error path 'array length
                           (format #f "Array too short: ~a < ~a" length min-items)))
                   '())
               (if (and max-items (> length max-items))
                   (list (make-validation-error path 'array length
                           (format #f "Array too long: ~a > ~a" length max-items)))
                   '())))
             (item-results
              (let loop ((items data) (index 0) (results '()))
                (if (null? items)
                    (reverse results)
                    (loop (cdr items)
                          (+ index 1)
                          (cons (validate (car items) item-spec 
                                        (append path (list index)))
                                results))))))
        (combine-results (cons (make-validation-result (null? length-errors)
                                                      length-errors)
                              item-results)))))

;;; Union validation
(define (validate-union data type-specs path)
  "Validate against any of the given types"
  (let ((results (map (lambda (spec) (validate data spec path)) type-specs)))
    (if (any validation-valid? results)
        (make-validation-result #t '())
        (make-validation-result #f
          (list (make-validation-error path type-specs (type-of data)
                  "Data doesn't match any union type"))))))

;;; Enum validation
(define (validate-enum data values path)
  "Validate against enumerated values"
  (if (member data values)
      (make-validation-result #t '())
      (make-validation-result #f
        (list (make-validation-error path values data
                (format #f "Value not in enum: ~s" data))))))

;;; Pattern validation
(define (validate-string-pattern data pattern path)
  "Validate string against regex pattern"
  (if (not (string? data))
      (make-validation-result #f
        (list (make-validation-error path 'string (type-of data)
                "Expected string for pattern matching")))
      (if (string-match pattern data)
          (make-validation-result #t '())
          (make-validation-result #f
            (list (make-validation-error path pattern data
                    (format #f "String doesn't match pattern: ~a" pattern)))))))

;;; Range validation
(define (validate-number-range data min max path)
  "Validate number within range"
  (if (not (number? data))
      (make-validation-result #f
        (list (make-validation-error path 'number (type-of data)
                "Expected number for range validation")))
      (if (and (>= data min) (<= data max))
          (make-validation-result #t '())
          (make-validation-result #f
            (list (make-validation-error path (list min max) data
                    (format #f "Number out of range: ~a not in [~a, ~a]" 
                            data min max)))))))

(define (validate-integer-range data min max path)
  "Validate integer within range"
  (if (not (and (number? data) (integer? data)))
      (make-validation-result #f
        (list (make-validation-error path 'integer (type-of data)
                "Expected integer for range validation")))
      (validate-number-range data min max path)))

;;; Helper functions
(define (assoc-ref alist key)
  "Get value from association list"
  (let ((pair (assoc key alist)))
    (if pair (cdr pair) #f)))

(define (combine-results results)
  "Combine multiple validation results"
  (make-validation-result
   (every validation-valid? results)
   (append-map validation-errors results)))

;;; Pretty printing
(define (format-validation-result result)
  "Format validation result for display"
  (if (validation-valid? result)
      "✓ Valid"
      (string-append
       "✗ Invalid:\n"
       (string-join
        (map (lambda (error)
               (format #f "  - ~a: ~a"
                       (string-join (map symbol->string (error-path error)) ".")
                       (error-message error)))
             (validation-errors result))
        "\n"))))

;;; Test the validator
(define (test-validator)
  (format #t "=== Validation Framework Tests ===\n\n")
  
  ;; Test 1: Simple types
  (format #t "Test 1: Simple type validation\n")
  (let ((result (validate "hello" 'string '())))
    (format #t "String validation: ~a\n" (format-validation-result result)))
  (let ((result (validate 42 'string '())))
    (format #t "Type mismatch: ~a\n" (format-validation-result result)))
  
  ;; Test 2: Object validation
  (format #t "\nTest 2: Object validation\n")
  (let* ((spec '((name . string)
                 (age . integer)
                 (email . (optional string))))
         (data '((name . "Alice") (age . 30)))
         (result (validate data spec '())))
    (format #t "Valid object: ~a\n" (format-validation-result result)))
  
  ;; Test 3: Array validation
  (format #t "\nTest 3: Array validation\n")
  (let* ((spec '(array string 2 5))
         (data '("one" "two" "three"))
         (result (validate data spec '())))
    (format #t "Valid array: ~a\n" (format-validation-result result)))
  
  ;; Test 4: Complex validation
  (format #t "\nTest 4: Complex nested validation\n")
  (let* ((spec '((user . (object
                          (name . string)
                          (roles . (array (enum "admin" "user" "guest")))))
                 (config . (object
                           (port . (integer-range 1 65535))
                           (host . (string-pattern "^[a-zA-Z0-9.-]+$"))))))
         (data '((user . ((name . "Bob") (roles . ("admin" "user"))))
                 (config . ((port . 8080) (host . "localhost")))))
         (result (validate data spec '())))
    (format #t "Complex validation: ~a\n" (format-validation-result result))))

;; Helper to convert symbols to strings
(define (symbol->string sym)
  (format #f "~a" sym))

;; Run tests if executed directly
(when (equal? (car (command-line)) "validator.scm")
  (test-validator)
  (format #t "\n✓ Validator tests complete!\n"))