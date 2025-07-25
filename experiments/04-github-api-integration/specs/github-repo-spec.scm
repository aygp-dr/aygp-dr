;;; github-repo-spec.scm - GitHub repository response specification

(define github-repo-spec
  '((id . integer)
    (node_id . string)
    (name . string)
    (full_name . string)
    (private . boolean)
    (owner . (object
              (login . string)
              (id . integer)
              (node_id . string)
              (avatar_url . string)
              (type . (enum "User" "Organization"))))
    (html_url . string)
    (description . (optional string))
    (fork . boolean)
    (created_at . string)  ; ISO 8601 datetime
    (updated_at . string)
    (pushed_at . string)
    (homepage . (optional string))
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
    (topics . (array string))
    (visibility . (enum "public" "private" "internal"))
    (default_branch . string)))

;;; Simplified repo spec for list operations
(define github-repo-list-spec
  '((id . integer)
    (name . string)
    (full_name . string)
    (description . (optional string))
    (language . (optional string))
    (stargazers_count . integer)
    (forks_count . integer)
    (topics . (array string))))

;;; Repository topics update spec
(define github-topics-spec
  '((names . (array string 0 20))))

;;; Export specs
(define (get-repo-spec) github-repo-spec)
(define (get-repo-list-spec) github-repo-list-spec)
(define (get-topics-spec) github-topics-spec)