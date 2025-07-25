#!/usr/bin/env guile
!#
;;; validation-tests.scm - Comprehensive test suite for validation framework

(load "validator.scm")
(load "spec-registry.scm")

(use-modules (ice-9 format)
             (srfi srfi-1))

;;; Test tracking
(define *tests-run* 0)
(define *tests-passed* 0)
(define *tests-failed* 0)

(define (run-test name test-fn)
  "Run a single test and track results"
  (set! *tests-run* (+ *tests-run* 1))
  (format #t "  ~a: " name)
  (catch #t
    (lambda ()
      (if (test-fn)
          (begin
            (set! *tests-passed* (+ *tests-passed* 1))
            (format #t "✓ PASS\n"))
          (begin
            (set! *tests-failed* (+ *tests-failed* 1))
            (format #t "✗ FAIL\n"))))
    (lambda (key . args)
      (set! *tests-failed* (+ *tests-failed* 1))
      (format #t "✗ ERROR: ~a\n" args))))

;;; Test suites
(define (test-basic-types)
  (format #t "\n=== Basic Type Tests ===\n")
  
  (run-test "String validation"
    (lambda ()
      (validation-valid? (validate "hello" 'string '()))))
  
  (run-test "Number validation"
    (lambda ()
      (validation-valid? (validate 42.5 'number '()))))
  
  (run-test "Integer validation"
    (lambda ()
      (validation-valid? (validate 42 'integer '()))))
  
  (run-test "Boolean validation"
    (lambda ()
      (validation-valid? (validate #t 'boolean '()))))
  
  (run-test "Null validation"
    (lambda ()
      (validation-valid? (validate '() 'null '()))))
  
  (run-test "Type mismatch detection"
    (lambda ()
      (not (validation-valid? (validate "string" 'number '()))))))

(define (test-object-validation)
  (format #t "\n=== Object Validation Tests ===\n")
  
  (run-test "Valid object"
    (lambda ()
      (let ((spec '((name . string) (age . integer)))
            (data '((name . "Alice") (age . 30))))
        (validation-valid? (validate data spec '())))))
  
  (run-test "Missing required field"
    (lambda ()
      (let ((spec '((name . string) (age . integer)))
            (data '((name . "Alice"))))
        (not (validation-valid? (validate data spec '()))))))
  
  (run-test "Optional field"
    (lambda ()
      (let ((spec '((name . string) (email . (optional string))))
            (data '((name . "Bob"))))
        (validation-valid? (validate data spec '())))))
  
  (run-test "Nested object"
    (lambda ()
      (let ((spec '((user . (object (name . string) (id . integer)))))
            (data '((user . ((name . "Charlie") (id . 123))))))
        (validation-valid? (validate data spec '()))))))

(define (test-array-validation)
  (format #t "\n=== Array Validation Tests ===\n")
  
  (run-test "Simple array"
    (lambda ()
      (let ((spec '(array string))
            (data '("one" "two" "three")))
        (validation-valid? (validate data spec '())))))
  
  (run-test "Array with min constraint"
    (lambda ()
      (let ((spec '(array number 2))
            (data '(1 2 3)))
        (validation-valid? (validate data spec '())))))
  
  (run-test "Array too short"
    (lambda ()
      (let ((spec '(array string 3))
            (data '("one")))
        (not (validation-valid? (validate data spec '()))))))
  
  (run-test "Array with min/max"
    (lambda ()
      (let ((spec '(array integer 2 5))
            (data '(1 2 3 4)))
        (validation-valid? (validate data spec '())))))
  
  (run-test "Array of objects"
    (lambda ()
      (let ((spec '(array (object (x . number) (y . number))))
            (data '(((x . 1) (y . 2)) ((x . 3) (y . 4)))))
        (validation-valid? (validate data spec '()))))))

(define (test-constraint-validation)
  (format #t "\n=== Constraint Validation Tests ===\n")
  
  (run-test "String pattern match"
    (lambda ()
      (let ((spec '(string-pattern "^[A-Z][a-z]+$"))
            (data "Hello"))
        (validation-valid? (validate data spec '())))))
  
  (run-test "String pattern mismatch"
    (lambda ()
      (let ((spec '(string-pattern "^[0-9]+$"))
            (data "abc"))
        (not (validation-valid? (validate data spec '()))))))
  
  (run-test "Number range valid"
    (lambda ()
      (let ((spec '(number-range 0 100))
            (data 50))
        (validation-valid? (validate data spec '())))))
  
  (run-test "Number out of range"
    (lambda ()
      (let ((spec '(number-range 0 10))
            (data 20))
        (not (validation-valid? (validate data spec '()))))))
  
  (run-test "Enum validation"
    (lambda ()
      (let ((spec '(enum "red" "green" "blue"))
            (data "green"))
        (validation-valid? (validate data spec '())))))
  
  (run-test "Enum invalid value"
    (lambda ()
      (let ((spec '(enum "yes" "no"))
            (data "maybe"))
        (not (validation-valid? (validate data spec '()))))))

(define (test-union-validation)
  (format #t "\n=== Union Type Tests ===\n")
  
  (run-test "Union with string"
    (lambda ()
      (let ((spec '(union string number))
            (data "hello"))
        (validation-valid? (validate data spec '())))))
  
  (run-test "Union with number"
    (lambda ()
      (let ((spec '(union string number))
            (data 42))
        (validation-valid? (validate data spec '())))))
  
  (run-test "Union type mismatch"
    (lambda ()
      (let ((spec '(union string number))
            (data #t))
        (not (validation-valid? (validate data spec '()))))))

(define (test-registry-integration)
  (format #t "\n=== Registry Integration Tests ===\n")
  
  ;; Register test specs
  (register-common-specs)
  
  (run-test "Email validation"
    (lambda ()
      (validation-valid? 
        (validate-with-spec "test@example.com" 'email))))
  
  (run-test "Invalid email"
    (lambda ()
      (not (validation-valid? 
             (validate-with-spec "not-an-email" 'email)))))
  
  (run-test "URL validation"
    (lambda ()
      (validation-valid? 
        (validate-with-spec "https://example.com/path" 'url))))
  
  (run-test "User with refs"
    (lambda ()
      (let ((user-data '((id . 1)
                        (username . "testuser")
                        (email . "test@example.com")
                        (created_at . 1234567890)
                        (active . #t))))
        (validation-valid? 
          (validate-with-spec user-data 'user)))))

(define (test-error-reporting)
  (format #t "\n=== Error Reporting Tests ===\n")
  
  (run-test "Error path tracking"
    (lambda ()
      (let* ((spec '((user . (object 
                             (name . string)
                             (contacts . (array (object
                                               (type . string)
                                               (value . string))))))))
             (data '((user . ((name . "Test")
                            (contacts . (((type . "email")
                                        (value . 123))))))))
             (result (validate data spec '()))
             (errors (validation-errors result)))
        (and (not (validation-valid? result))
             (> (length errors) 0)
             (equal? (error-path (car errors)) '(user contacts 0 value))))))

;;; Performance tests
(define (test-performance)
  (format #t "\n=== Performance Tests ===\n")
  
  (let* ((large-spec '((items . (array (object
                                       (id . integer)
                                       (name . string)
                                       (tags . (array string))
                                       (metadata . (object
                                                   (created . integer)
                                                   (updated . integer))))))))
         (large-data `((items . ,(map (lambda (i)
                                       `((id . ,i)
                                         (name . ,(format #f "Item ~a" i))
                                         (tags . ("tag1" "tag2"))
                                         (metadata . ((created . 1000)
                                                    (updated . 2000)))))
                                     (iota 100)))))
         (start-time (get-internal-real-time))
         (result (validate large-data large-spec '()))
         (end-time (get-internal-real-time))
         (elapsed-ms (/ (- end-time start-time) 1000.0)))
    
    (format #t "  Large dataset (100 items): ~a ms - " elapsed-ms)
    (if (validation-valid? result)
        (format #t "✓ PASS\n")
        (format #t "✗ FAIL\n"))))

;;; Main test runner
(define (run-all-tests)
  (format #t "=== Validation Framework Test Suite ===\n")
  (format #t "Running comprehensive tests...\n")
  
  (test-basic-types)
  (test-object-validation)
  (test-array-validation)
  (test-constraint-validation)
  (test-union-validation)
  (test-registry-integration)
  (test-error-reporting)
  (test-performance)
  
  (format #t "\n=== Test Summary ===\n")
  (format #t "Total tests: ~a\n" *tests-run*)
  (format #t "Passed: ~a\n" *tests-passed*)
  (format #t "Failed: ~a\n" *tests-failed*)
  (format #t "Success rate: ~a%\n" 
          (exact->inexact (/ (* 100 *tests-passed*) *tests-run*)))
  
  (if (= *tests-failed* 0)
      (format #t "\n✓ All tests passed!\n")
      (format #t "\n✗ Some tests failed!\n")))

;; Run tests if executed directly
(when (equal? (car (command-line)) "validation-tests.scm")
  (run-all-tests))