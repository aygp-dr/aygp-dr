# GitHub → Ollama Topic Generation Flow

## Sequence Diagram

```mermaid
sequenceDiagram
    participant User
    participant App as Workflow Engine
    participant Validator as Spec Validator
    participant GitHub as GitHub API
    participant Ollama as Ollama LLM
    participant GH_Update as GitHub Update
    
    Note over User,GH_Update: Repository Analysis & Topic Generation Flow
    
    %% Initial Request
    User->>App: Analyze my repositories
    App->>App: Load workflow definition
    
    %% Step 1: Get GitHub User
    Note over App,GitHub: Step 1: Fetch User Info
    App->>Validator: Validate request spec
    Validator-->>App: ✓ Valid
    App->>GitHub: GET /user (with token)
    GitHub-->>App: User data {login, id, ...}
    App->>Validator: Validate github-user spec
    Validator-->>App: ✓ Valid response
    App->>App: Store user in context
    
    %% Step 2: Get Repositories
    Note over App,GitHub: Step 2: Fetch Repositories
    App->>GitHub: GET /user/repos?per_page=100
    GitHub-->>App: Repos [{name, description, topics, ...}, ...]
    App->>Validator: Validate github-repo[] spec
    Validator-->>App: ✓ Valid array
    App->>App: Store repos in context
    
    %% Step 3: Get README for each repo
    Note over App,GitHub: Step 3: Fetch README Contents
    loop For each repository
        App->>GitHub: GET /repos/{owner}/{repo}/readme
        GitHub-->>App: README content (base64)
        App->>App: Decode and store
    end
    App->>Validator: Validate readme-content spec
    Validator-->>App: ✓ Valid content
    
    %% Step 4: Prepare Ollama prompt
    Note over App,Ollama: Step 4: Generate Topics via LLM
    App->>App: Build structured prompt with:<br/>- Repo name & description<br/>- Current topics<br/>- README content<br/>- Topic spec/schema
    
    App->>Validator: Validate ollama-request spec
    Validator-->>App: ✓ Valid request
    
    %% Step 5: Call Ollama with structured output
    App->>Ollama: POST /api/generate<br/>{model, prompt, format: {schema}}
    Note right of Ollama: Structured output:<br/>{"topics": ["api", "validation", ...]}
    Ollama-->>App: Generated topics (JSON)
    
    App->>Validator: Validate topics-response spec
    Validator-->>App: ✓ Valid ["string", ...]
    
    %% Step 6: Validate against GitHub constraints
    Note over App,Validator: Step 6: GitHub Topic Validation
    App->>Validator: Validate github-topics spec:<br/>- Max 20 topics<br/>- Valid characters<br/>- Length limits
    Validator-->>App: ✓ Valid for GitHub
    
    %% Step 7: Update repository
    Note over App,GH_Update: Step 7: Update Repository
    App->>GH_Update: PATCH /repos/{owner}/{repo}<br/>{topics: ["new", "topics", ...]}
    GH_Update-->>App: Updated repo data
    App->>Validator: Validate update response
    Validator-->>App: ✓ Success
    
    %% Final response
    App->>User: Analysis complete:<br/>- X repos analyzed<br/>- Y topics generated<br/>- Z repos updated
```

## Key Spec Domains & Validation Points

### 1. GitHub Request/Response Specs
```scheme
;; User spec
(register-spec 'github-user
  '((login . string)
    (id . integer)
    (type . (enum "User" "Organization"))))

;; Repository spec  
(register-spec 'github-repo
  '((name . string)
    (description . (optional string))
    (topics . (array string 0 20))  ; GitHub limit
    (visibility . (enum "public" "private"))))

;; README spec
(register-spec 'github-readme
  '((content . string)  ; base64 encoded
    (encoding . (enum "base64"))
    (size . integer)))

;; Topic update spec
(register-spec 'github-topic-update
  '((topics . (array (string-pattern "^[a-z0-9][a-z0-9-]*$") 0 20))))
```

### 2. Ollama Request/Response Specs
```scheme
;; Ollama request spec
(register-spec 'ollama-topic-request
  '((model . string)
    (prompt . string)
    (format . (object
               (type . "object")
               (properties . (object
                             (topics . (object
                                       (type . "array")
                                       (items . (object
                                                (type . "string")))
                                       (maxItems . 10)))))))
    (stream . boolean)))

;; Ollama response spec
(register-spec 'ollama-topic-response
  '((model . string)
    (response . string)  ; JSON string
    (done . boolean)))

;; Parsed topics spec
(register-spec 'generated-topics
  '((topics . (array string 1 10))))
```

### 3. Workflow Steps with Validation

```scheme
(define github-topic-workflow
  (create-workflow "github-topic-generation" 
    "Analyze repos and generate topics"
    
    ;; Fetch user
    (create-step 'fetch-user 'github-api
                 '((endpoint . "/user")))
    
    ;; Validate user response
    (create-step 'validate-user 'validate
                 '((input . fetch-user)
                   (spec . github-user))
                 'fetch-user)
    
    ;; Fetch repos
    (create-step 'fetch-repos 'github-api
                 '((endpoint . "/user/repos")
                   (params . ((per_page . 100)))))
    
    ;; Validate repos
    (create-step 'validate-repos 'validate
                 '((input . fetch-repos)
                   (spec . (array github-repo)))
                 'fetch-repos)
    
    ;; Fetch READMEs (parallel)
    (create-step 'fetch-readmes 'parallel-api
                 '((repos . validate-repos)
                   (endpoint-template . "/repos/{owner}/{name}/readme"))
                 'validate-repos)
    
    ;; Generate topics for each repo
    (create-step 'generate-topics 'ollama-structured
                 '((repos . validate-repos)
                   (readmes . fetch-readmes)
                   (schema . generated-topics))
                 'validate-repos 'fetch-readmes)
    
    ;; Validate generated topics
    (create-step 'validate-topics 'validate
                 '((input . generate-topics)
                   (spec . github-topic-update))
                 'generate-topics)
    
    ;; Update repos
    (create-step 'update-repos 'github-batch-update
                 '((repos . validate-repos)
                   (topics . validate-topics))
                 'validate-repos 'validate-topics)))
```

## Benefits of Spec-Driven Approach

1. **Type Safety**: Validate at boundaries between systems
2. **Clear Contracts**: Each API has defined input/output
3. **Error Prevention**: Catch issues before API calls
4. **Documentation**: Specs serve as documentation
5. **Testing**: Generate test data from specs
6. **Evolution**: Version specs as APIs change