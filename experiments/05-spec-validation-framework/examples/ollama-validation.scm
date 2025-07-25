#!/usr/bin/env guile
!#
;;; ollama-validation.scm - Validate Ollama API responses

(add-to-load-path "..")
(load "../validator.scm")
(load "../spec-registry.scm")

(use-modules (ice-9 format))

;;; Register Ollama-specific specs
(define (register-ollama-specs)
  ;; Model info spec
  (register-spec 'ollama-model
    '((name . string)
      (modified_at . string)
      (size . integer)
      (digest . string)
      (details . (optional (object
                           (format . string)
                           (family . string)
                           (families . (optional (array string)))
                           (parameter_size . string)
                           (quantization_level . string))))))
  
  ;; Generate request spec
  (register-spec 'ollama-generate-request
    '((model . string)
      (prompt . string)
      (format . (optional (union string object)))
      (options . (optional (object
                           (temperature . (number-range 0 2))
                           (top_p . (number-range 0 1))
                           (seed . (optional integer)))))
      (stream . (optional boolean))))
  
  ;; Generate response spec
  (register-spec 'ollama-generate-response
    '((model . string)
      (created_at . string)
      (response . string)
      (done . boolean)
      (context . (optional (array integer)))
      (total_duration . (optional integer))
      (load_duration . (optional integer))
      (prompt_eval_count . (optional integer))
      (prompt_eval_duration . (optional integer))
      (eval_count . (optional integer))
      (eval_duration . (optional integer))))
  
  ;; Structured output response
  (register-spec 'ollama-structured-response
    '((model . string)
      (created_at . string)
      (message . (object
                 (role . (enum "assistant" "user" "system"))
                 (content . string)))
      (done . boolean)
      (done_reason . (optional (enum "stop" "length" "timeout")))
      (total_duration . integer)
      (load_duration . integer)
      (prompt_eval_count . integer)
      (prompt_eval_duration . integer)
      (eval_count . integer)
      (eval_duration . integer))))

;;; Example validations
(define (validate-ollama-examples)
  (format #t "=== Ollama Response Validation Examples ===\n\n")
  
  ;; Register specs
  (register-ollama-specs)
  
  ;; Example 1: Valid generate request
  (format #t "Example 1: Generate Request Validation\n")
  (let* ((request '((model . "llama3.2:3b")
                   (prompt . "What is the capital of France?")
                   (stream . #f)
                   (options . ((temperature . 0.7)
                             (top_p . 0.9)))))
         (result (validate-with-spec request 'ollama-generate-request)))
    (format #t "Request: ~s\n" request)
    (format #t "Result: ~a\n\n" (format-validation-result result)))
  
  ;; Example 2: Invalid request (bad temperature)
  (format #t "Example 2: Invalid Request (temperature out of range)\n")
  (let* ((request '((model . "llama3.2:3b")
                   (prompt . "Test")
                   (options . ((temperature . 3.0)))))
         (result (validate-with-spec request 'ollama-generate-request)))
    (format #t "Request: ~s\n" request)
    (format #t "Result: ~a\n\n" (format-validation-result result)))
  
  ;; Example 3: Structured response validation
  (format #t "Example 3: Structured Response Validation\n")
  (let* ((response '((model . "llama3.2:3b")
                    (created_at . "2024-01-20T10:30:00Z")
                    (message . ((role . "assistant")
                               (content . "{\"answer\": \"Paris\"}")))
                    (done . #t)
                    (done_reason . "stop")
                    (total_duration . 1500000000)
                    (load_duration . 500000000)
                    (prompt_eval_count . 10)
                    (prompt_eval_duration . 100000000)
                    (eval_count . 5)
                    (eval_duration . 900000000)))
         (result (validate-with-spec response 'ollama-structured-response)))
    (format #t "Response: Valid structured response\n")
    (format #t "Result: ~a\n\n" (format-validation-result result)))
  
  ;; Example 4: Model list validation
  (format #t "Example 4: Model Info Validation\n")
  (let* ((model '((name . "llama3.2:3b")
                 (modified_at . "2024-01-15T08:00:00Z")
                 (size . 2000000000)
                 (digest . "sha256:abcdef123456")
                 (details . ((format . "gguf")
                           (family . "llama")
                           (parameter_size . "3B")
                           (quantization_level . "Q4_0")))))
         (result (validate-with-spec model 'ollama-model)))
    (format #t "Model: ~a\n" (assoc-ref model 'name))
    (format #t "Result: ~a\n\n" (format-validation-result result))))

;;; Custom validation for JSON content
(define (validate-json-content content expected-schema)
  "Validate that content string contains valid JSON matching schema"
  (format #t "Example 5: JSON Content Validation\n")
  (format #t "Content: ~a\n" content)
  (format #t "Note: Full JSON parsing would require a JSON library\n")
  (format #t "For now, checking if it looks like valid JSON\n")
  (let ((looks-valid (and (string? content)
                         (or (string-prefix? "{" content)
                             (string-prefix? "[" content)))))
    (format #t "Appears to be JSON: ~a\n\n" (if looks-valid "✓" "✗"))))

;; Utility function
(define (string-prefix? prefix str)
  (and (>= (string-length str) (string-length prefix))
       (string=? (substring str 0 (string-length prefix)) prefix)))

;; Run examples
(validate-ollama-examples)
(validate-json-content "{\"languages\": [\"Python\", \"JavaScript\"]}" 
                      '((languages . (array string))))

(format #t "✓ Ollama validation examples complete!\n")