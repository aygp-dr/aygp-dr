;;; github-user-spec.scm - GitHub user response specification

(define github-user-spec
  '((login . string)
    (id . integer)
    (node_id . string)
    (avatar_url . string)
    (gravatar_id . (optional string))
    (url . string)
    (html_url . string)
    (type . (enum "User" "Organization"))
    (site_admin . boolean)
    (name . (optional string))
    (company . (optional string))
    (blog . (optional string))
    (location . (optional string))
    (email . (optional string))
    (hireable . (optional boolean))
    (bio . (optional string))
    (twitter_username . (optional string))
    (public_repos . integer)
    (public_gists . integer)
    (followers . integer)
    (following . integer)
    (created_at . string)
    (updated_at . string)))

;;; Simplified user spec for list operations
(define github-user-summary-spec
  '((login . string)
    (id . integer)
    (avatar_url . string)
    (type . (enum "User" "Organization"))))

;;; User search result spec
(define github-user-search-spec
  '((total_count . integer)
    (incomplete_results . boolean)
    (items . (array (object
                    (login . string)
                    (id . integer)
                    (avatar_url . string)
                    (type . (enum "User" "Organization"))
                    (score . number))))))

;;; Export specs
(define (get-user-spec) github-user-spec)
(define (get-user-summary-spec) github-user-summary-spec)
(define (get-user-search-spec) github-user-search-spec)