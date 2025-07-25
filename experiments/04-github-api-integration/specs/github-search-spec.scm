;;; github-search-spec.scm - GitHub search response specifications

;;; Repository search response
(define github-repo-search-spec
  '((total_count . integer)
    (incomplete_results . boolean)
    (items . (array (object
                    (id . integer)
                    (name . string)
                    (full_name . string)
                    (description . (optional string))
                    (private . boolean)
                    (owner . (object
                             (login . string)
                             (id . integer)
                             (type . (enum "User" "Organization"))))
                    (html_url . string)
                    (language . (optional string))
                    (stargazers_count . integer)
                    (forks_count . integer)
                    (topics . (array string))
                    (score . number))))))

;;; Code search response
(define github-code-search-spec
  '((total_count . integer)
    (incomplete_results . boolean)
    (items . (array (object
                    (name . string)
                    (path . string)
                    (sha . string)
                    (url . string)
                    (git_url . string)
                    (html_url . string)
                    (repository . (object
                                  (id . integer)
                                  (name . string)
                                  (full_name . string)
                                  (owner . (object
                                           (login . string)
                                           (id . integer)))))
                    (score . number))))))

;;; Issue search response
(define github-issue-search-spec
  '((total_count . integer)
    (incomplete_results . boolean)
    (items . (array (object
                    (id . integer)
                    (number . integer)
                    (title . string)
                    (state . (enum "open" "closed"))
                    (body . (optional string))
                    (user . (object
                            (login . string)
                            (id . integer)))
                    (labels . (array (object
                                     (name . string)
                                     (color . string))))
                    (created_at . string)
                    (updated_at . string)
                    (score . number))))))

;;; Search qualifiers spec
(define github-search-qualifiers
  '((q . string)  ; The search query
    (sort . (optional (enum "stars" "forks" "help-wanted-issues" "updated")))
    (order . (optional (enum "asc" "desc")))
    (per_page . (optional (integer-range 1 100)))
    (page . (optional integer))))

;;; Export specs
(define (get-repo-search-spec) github-repo-search-spec)
(define (get-code-search-spec) github-code-search-spec)
(define (get-issue-search-spec) github-issue-search-spec)
(define (get-search-qualifiers) github-search-qualifiers)