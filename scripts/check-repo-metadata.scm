#!/usr/bin/env guile
!#
;;; check-repo-metadata.scm - Check and audit GitHub repository metadata
;;; Uses GitHub REST API to analyze repository descriptions and topics

(use-modules (ice-9 format)
             (ice-9 popen)
             (ice-9 rdelim)
             (ice-9 regex)
             (ice-9 match)
             (srfi srfi-1))

;;; ANSI color codes
(define *green* "\x1b[0;32m")
(define *yellow* "\x1b[1;33m")
(define *red* "\x1b[0;31m")
(define *reset* "\x1b[0m")

;;; Execute shell command and return output
(define (shell-command->string cmd)
  (let* ((port (open-pipe* OPEN_READ "/bin/sh" "-c" cmd))
         (output (read-string port)))
    (close-pipe port)
    (string-trim-right output)))

;;; Get authenticated GitHub user
(define (get-github-user)
  (shell-command->string "gh api user --jq .login"))

;;; Simple JSON parser for the gh output
(define (parse-json-array str)
  ;; Very basic JSON array parser - just extract the fields we need
  ;; This is a simplified approach since we don't have guile-json
  (let ((repos '()))
    ;; Process each repository object
    (let loop ((remaining str))
      (cond
        ((string-match "\\{[^}]+\\}" remaining)
         => (lambda (m)
              (let* ((repo-str (match:substring m))
                     (name (extract-json-field repo-str "name"))
                     (desc (extract-json-field repo-str "description"))
                     (topics (extract-topics repo-str)))
                (set! repos (cons (list (cons "name" name)
                                      (cons "description" desc)
                                      (cons "repositoryTopics" topics))
                                repos))
                (loop (match:suffix m)))))
        (else repos)))
    (reverse repos)))

;;; Extract a JSON field value
(define (extract-json-field json-str field)
  (let ((pattern (string-append "\"" field "\":\\s*\"([^\"]*)\"")))
    (cond
      ((string-match pattern json-str)
       => (lambda (m) (match:substring m 1)))
      ((string-match (string-append "\"" field "\":\\s*null") json-str)
       #f)
      (else #f))))

;;; Extract repository topics
(define (extract-topics json-str)
  (let ((topics '()))
    (cond
      ((string-match "\"repositoryTopics\":\\s*\\[([^\\]]*)\\]" json-str)
       => (lambda (m)
            (let ((topics-str (match:substring m 1)))
              (let loop ((remaining topics-str))
                (cond
                  ((string-match "\"name\":\\s*\"([^\"]*)\"" remaining)
                   => (lambda (tm)
                        (set! topics (cons (list (cons "name" (match:substring tm 1))) topics))
                        (loop (match:suffix tm))))
                  (else (reverse topics)))))))
      (else '())))

;;; Get all public repositories for a user
(define (get-user-repos user)
  (let* ((cmd (format #f "gh repo list ~a --visibility public --no-archived --limit 100 --json name,description,visibility,repositoryTopics" user))
         (json-str (shell-command->string cmd)))
    (parse-json-array json-str)))

;;; Check if description is adequate
(define (check-description desc)
  (cond
    ((or (not desc) (string-null? desc))
     (list 'missing "Missing description"))
    ((< (string-length desc) 20)
     (list 'short (format #f "Description too short (~a chars)" (string-length desc))))
    (else
     (list 'ok (format #f "Description (~a chars)" (string-length desc))))))

;;; Check if topics are adequate
(define (check-topics topics)
  (let ((count (length topics)))
    (cond
      ((= count 0)
       (list 'missing "Missing topics"))
      ((< count 3)
       (list 'few (format #f "Only ~a topics" count)))
      (else
       (list 'ok (format #f "~a topics" count))))))

;;; Get topic names from topic objects
(define (extract-topic-names topics)
  (map (lambda (topic) (assoc-ref topic "name")) topics))

;;; Suggest topics based on repository name
(define (suggest-topics-for-name repo-name)
  (cond
    ((string-match "python|py$" repo-name)
     '("python" "python3" "python-library"))
    ((string-match "javascript|js$" repo-name)
     '("javascript" "nodejs" "npm"))
    ((string-match "rust|rs$" repo-name)
     '("rust" "cargo" "rust-lang"))
    ((string-match "go|golang" repo-name)
     '("go" "golang" "go-module"))
    ((string-match "scheme|scm$|guile" repo-name)
     '("scheme" "guile" "lisp" "functional-programming"))
    ((string-match "clojure|clj$" repo-name)
     '("clojure" "clojurescript" "jvm"))
    ((string-match "ml|ai|learning" repo-name)
     '("machine-learning" "ai" "artificial-intelligence"))
    ((string-match "api" repo-name)
     '("api" "rest-api" "web-api"))
    ((string-match "cli|command" repo-name)
     '("cli" "command-line" "terminal"))
    (else
     '("Add language and purpose-specific topics"))))

;;; Format a repository report
(define (format-repo-report repo user)
  (let* ((name (assoc-ref repo "name"))
         (desc (assoc-ref repo "description"))
         (topics (assoc-ref repo "repositoryTopics"))
         (topic-names (extract-topic-names topics))
         (desc-check (check-description desc))
         (topic-check (check-topics topics)))
    
    (format #t "~aRepository: ~a~a~%" *green* name *reset*)
    (format #t "Visibility: Public~%")
    
    ;; Description check
    (case (car desc-check)
      ((missing)
       (format #t "~a⚠️  ~a~a~%" *red* (cadr desc-check) *reset*)
       (format #t "Suggested action: gh repo edit ~a/~a --description \"Your description here\"~%" user name))
      ((short)
       (format #t "~a⚠️  ~a~a: ~a~%" *yellow* (cadr desc-check) *reset* desc)
       (format #t "Suggested action: gh repo edit ~a/~a --description \"...\"~%" user name))
      ((ok)
       (format #t "~a: ~a~%" (cadr desc-check) desc)))
    
    ;; Topics check
    (case (car topic-check)
      ((missing)
       (format #t "~a⚠️  ~a~a~%" *red* (cadr topic-check) *reset*)
       (format #t "Suggested action: gh repo edit ~a/~a --add-topic " user name)
       (format #t "~{~a~^,~}~%" (suggest-topics-for-name name))
       (format #t "~aSuggested topics based on name:~a ~{~a ~}~%" 
               *yellow* *reset* (suggest-topics-for-name name)))
      ((few)
       (format #t "~a⚠️  ~a~a: ~{~a ~}~%" *yellow* (cadr topic-check) *reset* topic-names)
       (format #t "Suggested action: gh repo edit ~a/~a --add-topic topic1,topic2~%" user name))
      ((ok)
       (format #t "~a: ~{~a ~}~%" (cadr topic-check) topic-names)))
    
    (format #t "============================================================~%")))

;;; Main program
(define (main)
  (let* ((user (get-github-user))
         (repos (get-user-repos user)))
    
    (format #t "Checking repository metadata for ~a...~%" user)
    (format #t "============================================================~%")
    
    (for-each (lambda (repo) (format-repo-report repo user)) repos)
    
    (format #t "Metadata check complete!~%~%")
    (format #t "GitHub API endpoints used:~%")
    (format #t "  - GET /user - Get authenticated user~%")
    (format #t "  - GET /users/{user}/repos - List user repositories~%")
    (format #t "  - PATCH /repos/{owner}/{repo} - Edit repository (for fixes)~%")))

;;; Run main program
(main)