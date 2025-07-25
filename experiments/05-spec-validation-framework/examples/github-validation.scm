#!/usr/bin/env guile
!#
;;; github-validation.scm - Validate GitHub API responses

(add-to-load-path "..")
(load "../validator.scm")
(load "../spec-registry.scm")

(use-modules (ice-9 format))

;;; Register GitHub-specific specs
(define (register-github-specs)
  ;; User spec
  (register-spec 'github-user
    '((login . string)
      (id . integer)
      (node_id . string)
      (avatar_url . url)
      (gravatar_id . (optional string))
      (url . url)
      (html_url . url)
      (type . (enum "User" "Organization"))
      (site_admin . boolean)
      (name . (optional string))
      (company . (optional string))
      (blog . (optional string))
      (location . (optional string))
      (email . (optional email))
      (bio . (optional string))
      (public_repos . integer)
      (public_gists . integer)
      (followers . integer)
      (following . integer)
      (created_at . timestamp)
      (updated_at . timestamp)))
  
  ;; Repository spec
  (register-spec 'github-repo
    '((id . integer)
      (node_id . string)
      (name . string)
      (full_name . string)
      (private . boolean)
      (owner . (object
               (login . string)
               (id . integer)
               (avatar_url . url)
               (type . (enum "User" "Organization"))))
      (html_url . url)
      (description . (optional string))
      (fork . boolean)
      (created_at . timestamp)
      (updated_at . timestamp)
      (pushed_at . (optional timestamp))
      (homepage . (optional url))
      (size . integer)
      (stargazers_count . integer)
      (watchers_count . integer)
      (language . (optional string))
      (has_issues . boolean)
      (has_projects . boolean)
      (has_downloads . boolean)
      (has_wiki . boolean)
      (has_pages . boolean)
      (forks_count . integer)
      (archived . boolean)
      (disabled . boolean)
      (open_issues_count . integer)
      (license . (optional (object
                           (key . string)
                           (name . string)
                           (spdx_id . string)
                           (url . (optional url)))))
      (topics . (array string))
      (visibility . (enum "public" "private" "internal"))
      (default_branch . string)))
  
  ;; Search results spec
  (register-spec 'github-search-results
    '((total_count . integer)
      (incomplete_results . boolean)
      (items . (array (ref github-repo)))))
  
  ;; Rate limit spec
  (register-spec 'github-rate-limit
    '((resources . (object
                   (core . (object
                           (limit . integer)
                           (remaining . integer)
                           (reset . integer)
                           (used . integer)))
                   (search . (object
                             (limit . integer)
                             (remaining . integer)
                             (reset . integer)
                             (used . integer)))
                   (graphql . (optional (object
                                       (limit . integer)
                                       (remaining . integer)
                                       (reset . integer)
                                       (used . integer))))))
      (rate . (object
              (limit . integer)
              (remaining . integer)
              (reset . integer)
              (used . integer)))))
  
  ;; Error response spec
  (register-spec 'github-error
    '((message . string)
      (documentation_url . url)
      (errors . (optional (array (object
                                 (resource . string)
                                 (field . string)
                                 (code . string))))))))

;;; Example validations
(define (validate-github-examples)
  (format #t "=== GitHub API Response Validation Examples ===\n\n")
  
  ;; Register common specs first
  (register-common-specs)
  ;; Then GitHub specs
  (register-github-specs)
  
  ;; Example 1: Valid user response
  (format #t "Example 1: User Response Validation\n")
  (let* ((user '((login . "octocat")
                (id . 1)
                (node_id . "MDQ6VXNlcjE=")
                (avatar_url . "https://github.com/images/error/octocat_happy.gif")
                (url . "https://api.github.com/users/octocat")
                (html_url . "https://github.com/octocat")
                (type . "User")
                (site_admin . #f)
                (name . "The Octocat")
                (company . "GitHub")
                (blog . "https://github.blog")
                (location . "San Francisco")
                (email . "octocat@github.com")
                (bio . "GitHub mascot")
                (public_repos . 8)
                (public_gists . 8)
                (followers . 3000)
                (following . 9)
                (created_at . "2008-01-14T04:33:35Z")
                (updated_at . "2024-01-20T10:00:00Z")))
         (result (validate-with-spec user 'github-user)))
    (format #t "User: ~a\n" (assoc-ref user 'login))
    (format #t "Result: ~a\n\n" (format-validation-result result)))
  
  ;; Example 2: Repository validation
  (format #t "Example 2: Repository Response Validation\n")
  (let* ((repo '((id . 1296269)
                (node_id . "MDEwOlJlcG9zaXRvcnkxMjk2MjY5")
                (name . "Hello-World")
                (full_name . "octocat/Hello-World")
                (private . #f)
                (owner . ((login . "octocat")
                         (id . 1)
                         (avatar_url . "https://github.com/images/error/octocat_happy.gif")
                         (type . "User")))
                (html_url . "https://github.com/octocat/Hello-World")
                (description . "My first repository on GitHub!")
                (fork . #f)
                (created_at . "2011-01-26T19:01:12Z")
                (updated_at . "2024-01-20T10:00:00Z")
                (pushed_at . "2024-01-19T15:30:00Z")
                (size . 180)
                (stargazers_count . 80)
                (watchers_count . 80)
                (language . "C")
                (has_issues . #t)
                (has_projects . #t)
                (has_downloads . #t)
                (has_wiki . #t)
                (has_pages . #f)
                (forks_count . 9)
                (archived . #f)
                (disabled . #f)
                (open_issues_count . 0)
                (topics . ("octocat" "atom" "electron" "api"))
                (visibility . "public")
                (default_branch . "master")))
         (result (validate-with-spec repo 'github-repo)))
    (format #t "Repository: ~a\n" (assoc-ref repo 'full_name))
    (format #t "Result: ~a\n\n" (format-validation-result result)))
  
  ;; Example 3: Rate limit response
  (format #t "Example 3: Rate Limit Response Validation\n")
  (let* ((rate-limit '((resources . ((core . ((limit . 5000)
                                             (remaining . 4999)
                                             (reset . 1372700873)
                                             (used . 1)))
                                    (search . ((limit . 30)
                                              (remaining . 18)
                                              (reset . 1372697452)
                                              (used . 12)))))
                      (rate . ((limit . 5000)
                              (remaining . 4999)
                              (reset . 1372700873)
                              (used . 1)))))
         (result (validate-with-spec rate-limit 'github-rate-limit)))
    (format #t "Rate limit: ~a/~a\n" 
            (assoc-ref (assoc-ref rate-limit 'rate) 'remaining)
            (assoc-ref (assoc-ref rate-limit 'rate) 'limit))
    (format #t "Result: ~a\n\n" (format-validation-result result)))
  
  ;; Example 4: Error response
  (format #t "Example 4: Error Response Validation\n")
  (let* ((error '((message . "Not Found")
                 (documentation_url . "https://docs.github.com/rest/reference/repos#get-a-repository")
                 (errors . #(((resource . "Repository")
                            (field . "name")
                            (code . "invalid"))))))
         (result (validate-with-spec error 'github-error)))
    (format #t "Error: ~a\n" (assoc-ref error 'message))
    (format #t "Result: ~a\n\n" (format-validation-result result))))

;;; Validate paginated responses
(define (validate-pagination-headers headers)
  "Validate GitHub pagination headers"
  (format #t "Example 5: Pagination Headers Validation\n")
  (let* ((link-spec '((link . (optional string))
                     (x-ratelimit-limit . string)
                     (x-ratelimit-remaining . string)
                     (x-ratelimit-reset . string)))
         (result (validate headers link-spec '())))
    (format #t "Headers: Link header present\n")
    (format #t "Result: ~a\n\n" (format-validation-result result))))

;; Run examples
(validate-github-examples)
(validate-pagination-headers 
  '((link . "<https://api.github.com/search/code?q=addClass+user%3Amozilla&page=2>; rel=\"next\"")
    (x-ratelimit-limit . "60")
    (x-ratelimit-remaining . "59")
    (x-ratelimit-reset . "1372700873")))

(format #t "✓ GitHub validation examples complete!\n")