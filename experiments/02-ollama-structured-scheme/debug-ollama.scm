#!/usr/bin/env guile
!#
;;; Debug Ollama connection

(use-modules (ice-9 format)
             (ice-9 popen)
             (ice-9 rdelim))

(define (test-ollama)
  (let* ((cmd "curl -X POST http://localhost:11434/api/generate -H 'Content-Type: application/json' -d '{\"model\":\"llama3.2:3b\",\"prompt\":\"Hello\",\"stream\":false}' -s")
         (port (open-pipe* OPEN_READ "/bin/sh" "-c" cmd))
         (response (read-string port)))
    (close-pipe port)
    (format #t "Response: ~a~%" response)))

(test-ollama)