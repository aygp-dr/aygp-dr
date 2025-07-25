#!/usr/bin/env guile
!#
;;; example-schemas.scm - Example schemas for common use cases

;;; GitHub Repository Metadata Schema
(define github-repo-spec
  '((name . string)
    (description . (optional string))
    (topics . (array string 0 20))
    (visibility . (enum "public" "private" "internal"))
    (language . (optional string))
    (created_at . string)
    (updated_at . string)))

;;; Ollama Chat Message Schema
(define ollama-message-spec
  '((role . (enum "system" "user" "assistant"))
    (content . string)
    (images . (optional (array string)))))

;;; API Response Schema
(define api-response-spec
  '((status . (enum "success" "error"))
    (data . (optional (object
                      (results . (array (object
                                        (id . integer)
                                        (name . string))))
                      (total . integer))))
    (error . (optional (object
                       (code . string)
                       (message . string))))))

;;; Repository Analysis Result Schema
(define repo-analysis-spec
  '((repository . string)
    (analysis_date . string)
    (metadata_quality . (object
                        (description . (enum "missing" "poor" "adequate" "excellent"))
                        (topics . (enum "missing" "insufficient" "adequate" "comprehensive"))))
    (suggestions . (object
                   (description . (optional string))
                   (topics_to_add . (array string))
                   (topics_to_remove . (array string))))
    (score . (number-range 0 100))))

;;; Print example conversions
(define (show-examples)
  (load "spec-json-converter.scm")
  
  (format #t "~%=== GitHub Repository Schema ===~%")
  (format #t "Spec: ~s~%" github-repo-spec)
  (format #t "JSON Schema: ~s~%" (spec->json-schema github-repo-spec))
  
  (format #t "~%=== Repository Analysis Schema ===~%")
  (format #t "Spec: ~s~%" repo-analysis-spec)
  (format #t "JSON Schema: ~s~%" (spec->json-schema repo-analysis-spec)))

;; Uncomment to run examples
;; (show-examples)