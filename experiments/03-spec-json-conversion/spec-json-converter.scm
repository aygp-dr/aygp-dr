#!/usr/bin/env guile
!#
;;; spec-json-converter.scm - Bidirectional conversion between Scheme specs and JSON schemas
;;; Demonstrates converting between two schema representation formats

(use-modules (ice-9 match)
             (ice-9 format)
             (srfi srfi-1)
             (srfi srfi-9))

;;; ===== Data Structures =====

(define-record-type <spec-field>
  (make-spec-field name type-expr)
  spec-field?
  (name spec-field-name)
  (type-expr spec-field-type))

;;; ===== Spec to JSON Schema Conversion =====

(define (spec->json-schema spec)
  "Convert a Scheme spec to JSON Schema format"
  (list (cons 'type "object")
        (cons 'properties (spec-properties->json spec))
        (cons 'required (extract-required-fields spec))))

(define (spec-properties->json spec)
  "Convert spec properties to JSON Schema properties"
  (map (lambda (field)
         (cons (car field)
               (type-expr->json-schema (cdr field))))
       spec))

(define (type-expr->json-schema expr)
  "Convert a type expression to JSON Schema format"
  (match expr
    ;; Basic types
    ('string '((type . "string")))
    ('number '((type . "number")))
    ('integer '((type . "integer")))
    ('boolean '((type . "boolean")))
    ('null '((type . "null")))
    
    ;; Array types
    (('array item-type)
     `((type . "array")
       (items . ,(type-expr->json-schema item-type))))
    
    (('array item-type min max)
     `((type . "array")
       (items . ,(type-expr->json-schema item-type))
       (minItems . ,min)
       (maxItems . ,max)))
    
    ;; Object types
    (('object . nested-spec)
     `((type . "object")
       (properties . ,(spec-properties->json nested-spec))
       (required . ,(extract-required-fields nested-spec))))
    
    ;; Optional types
    (('optional inner-type)
     (type-expr->json-schema inner-type))
    
    ;; Union types
    (('union . types)
     `((oneOf . ,(map type-expr->json-schema types))))
    
    ;; Enum types
    (('enum . values)
     `((type . "string")
       (enum . ,values)))
    
    ;; Constraint types
    (('string-pattern pattern)
     `((type . "string")
       (pattern . ,pattern)))
    
    (('number-range min max)
     `((type . "number")
       (minimum . ,min)
       (maximum . ,max)))
    
    ;; Default case
    (else `((type . "string")))))

(define (extract-required-fields spec)
  "Extract required fields from spec (non-optional ones)"
  (filter-map (lambda (field)
                (match (cdr field)
                  (('optional . _) #f)
                  (_ (symbol->string (car field)))))
              spec))

;;; ===== JSON Schema to Spec Conversion =====

(define (json-schema->spec schema)
  "Convert JSON Schema to Scheme spec format"
  (let ((type (assoc-ref schema 'type)))
    (cond
      ((string=? type "object")
       (json-object->spec schema))
      (else
       (list (cons 'value (json-type->spec-type schema)))))))

(define (json-object->spec schema)
  "Convert JSON Schema object to spec"
  (let ((properties (assoc-ref schema 'properties))
        (required (assoc-ref schema 'required)))
    (map (lambda (prop)
           (let* ((name (car prop))
                  (prop-schema (cdr prop))
                  (type-expr (json-type->spec-type prop-schema))
                  (is-required? (member (symbol->string name) 
                                      (vector->list (or required #())))))
             (cons name (if is-required?
                           type-expr
                           (list 'optional type-expr)))))
         properties)))

(define (json-type->spec-type schema)
  "Convert JSON Schema type to spec type expression"
  (let ((type (assoc-ref schema 'type)))
    (cond
      ;; Basic types
      ((string=? type "string")
       (cond
         ((assoc-ref schema 'pattern)
          => (lambda (pattern) (list 'string-pattern pattern)))
         ((assoc-ref schema 'enum)
          => (lambda (values) (cons 'enum values)))
         (else 'string)))
      
      ((string=? type "number")
       (let ((min (assoc-ref schema 'minimum))
             (max (assoc-ref schema 'maximum)))
         (if (and min max)
             (list 'number-range min max)
             'number)))
      
      ((string=? type "integer") 'integer)
      ((string=? type "boolean") 'boolean)
      ((string=? type "null") 'null)
      
      ;; Array type
      ((string=? type "array")
       (let ((items (assoc-ref schema 'items))
             (min (assoc-ref schema 'minItems))
             (max (assoc-ref schema 'maxItems)))
         (if (and min max)
             (list 'array (json-type->spec-type items) min max)
             (list 'array (json-type->spec-type items)))))
      
      ;; Object type
      ((string=? type "object")
       (cons 'object (json-object->spec schema)))
      
      ;; Union type
      ((assoc-ref schema 'oneOf)
       => (lambda (types)
            (cons 'union (map json-type->spec-type types))))
      
      ;; Default
      (else 'string))))

;;; ===== Utility Functions =====

(define (assoc-ref alist key)
  "Get value from association list"
  (let ((pair (assoc key alist)))
    (if pair (cdr pair) #f)))

(define (symbol->string sym)
  "Convert symbol to string"
  (format #f "~a" sym))

(define (string=? s1 s2)
  "Compare two strings"
  (equal? s1 s2))

(define (member item lst)
  "Check if item is in list"
  (and (memq item lst) #t))

(define (vector->list vec)
  "Convert vector to list"
  (if (vector? vec)
      (let loop ((i 0) (acc '()))
        (if (< i (vector-length vec))
            (loop (+ i 1) (cons (vector-ref vec i) acc))
            (reverse acc)))
      '()))

;;; ===== Test Functions =====

(define (test-conversions)
  "Test bidirectional conversions"
  (format #t "~%=== Testing Spec to JSON Schema Conversion ===~%~%")
  
  ;; Test 1: Simple object
  (let* ((spec1 '((name . string)
                  (age . integer)
                  (active . boolean)))
         (json1 (spec->json-schema spec1)))
    (format #t "Test 1 - Simple object:~%")
    (format #t "Spec: ~s~%" spec1)
    (format #t "JSON Schema: ~s~%~%" json1))
  
  ;; Test 2: With optional fields
  (let* ((spec2 '((id . integer)
                  (name . string)
                  (email . (optional string))
                  (tags . (array string))))
         (json2 (spec->json-schema spec2)))
    (format #t "Test 2 - Optional fields:~%")
    (format #t "Spec: ~s~%" spec2)
    (format #t "JSON Schema: ~s~%~%" json2))
  
  ;; Test 3: Complex nested structure
  (let* ((spec3 '((repository . string)
                  (metadata . (object
                              (description . string)
                              (topics . (array string 3 20))
                              (language . (enum "scheme" "python" "rust"))))))
         (json3 (spec->json-schema spec3)))
    (format #t "Test 3 - Complex structure:~%")
    (format #t "Spec: ~s~%" spec3)
    (format #t "JSON Schema: ~s~%~%" json3))
  
  ;; Test 4: Round-trip conversion
  (format #t "~%=== Testing Round-Trip Conversion ===~%~%")
  (let* ((original-spec '((name . string)
                         (count . (number-range 0 100))
                         (type . (enum "A" "B" "C"))))
         (as-json (spec->json-schema original-spec))
         (back-to-spec (json-schema->spec as-json)))
    (format #t "Original spec: ~s~%" original-spec)
    (format #t "As JSON Schema: ~s~%" as-json)
    (format #t "Back to spec: ~s~%" back-to-spec)
    (format #t "Round-trip successful: ~a~%"
            (equal? (spec->json-schema back-to-spec) as-json))))

(define (test-ollama-schema)
  "Test conversion of Ollama-style schema"
  (format #t "~%=== Testing Ollama Schema Format ===~%~%")
  
  (let* ((ollama-spec '((repository . string)
                       (description . string)
                       (main_topics . (array string))
                       (key_features . (array string))
                       (use_cases . (array string))))
         (json-schema (spec->json-schema ollama-spec)))
    
    (format #t "Ollama-style spec:~%~s~%~%" ollama-spec)
    (format #t "Converted to JSON Schema:~%~s~%~%" json-schema)
    
    ;; Simulate what would be sent to Ollama
    (format #t "Format parameter for Ollama API:~%")
    (format #t "{~%")
    (format #t "  \"format\": ~a~%" (schema->json-string json-schema))
    (format #t "}~%")))

(define (schema->json-string schema)
  "Convert schema to JSON string representation"
  ;; Simplified JSON string generation
  (format #f "{~a}"
          (string-join
           (map (lambda (pair)
                  (format #f "\"~a\":~a"
                          (car pair)
                          (value->json-string (cdr pair))))
                schema)
           ",")))

(define (value->json-string val)
  "Convert a value to JSON string"
  (cond
    ((string? val) (format #f "\"~a\"" val))
    ((number? val) (format #f "~a" val))
    ((list? val) 
     (if (and (pair? val) (symbol? (car val)))
         (schema->json-string val)
         (format #f "[~a]" 
                 (string-join (map value->json-string val) ","))))
    (else "null")))

;;; ===== Main Program =====

(define (main)
  (format #t "=== Scheme Spec <-> JSON Schema Converter ===~%")
  (format #t "Demonstrating bidirectional conversion~%")
  
  (test-conversions)
  (test-ollama-schema)
  
  (format #t "~%Experiment complete!~%"))

;; Run the main program
(main)