# Experiment 06 Findings: API Composition

## Date: 2025-07-25

### Key Learnings

1. **Workflow Engine Architecture**
   - Step-based execution with dependency resolution
   - Topological sorting ensures correct execution order
   - Context object maintains state between steps
   - Extensible executor registry pattern

2. **Quasiquote vs Quote**
   - Must use quasiquote (`) when embedding expressions
   - Regular quote (') prevents evaluation of embedded lambdas
   - Critical for passing functions in configuration

3. **Error Handling in Workflows**
   - Each step wrapped in catch block
   - Errors logged but workflow continues
   - Context tracks all errors for debugging

4. **Data Flow Patterns**
   - Steps reference outputs by step ID
   - Hash table for fast lookup of step results
   - Support for parallel execution paths

### Technical Achievements

1. **Workflow Engine Features**
   - Dependency resolution with topological sort
   - Built-in executors (transform, validate, merge, filter, api-call)
   - Extensible executor registration
   - Comprehensive error tracking and logging

2. **API Composition Patterns**
   - Sequential API calls with data passing
   - Parallel API calls with result merging
   - Data transformation between API formats
   - Validation at each step

3. **Example Workflows**
   - Repository analysis (GitHub → Ollama)
   - Code review automation
   - ETL-style data pipelines
   - Multi-source data aggregation

### Implementation Challenges

1. **Function Serialization**
   - Cannot serialize lambdas with regular quote
   - Quasiquote required for embedded functions
   - Configuration becomes code, not just data

2. **Step Dependencies**
   - Manual dependency declaration required
   - No automatic dependency detection
   - Circular dependencies not detected

3. **Type Safety**
   - No compile-time checking of step compatibility
   - Runtime errors when data shapes don't match
   - Need careful documentation of step contracts

### Usage Patterns

```scheme
;; Define workflow
(define workflow
  (create-workflow "name" "description"
    (create-step 'step1 'api-call '((endpoint . "/data")))
    (create-step 'step2 'transform 
                 `((input . step1)
                   (transform . ,(lambda (data) ...)))
                 'step1)))

;; Execute workflow
(define result (execute-workflow workflow initial-data))
```

### Performance Considerations

- Step execution is sequential (could be parallelized)
- Context uses hash tables for O(1) lookups
- Topological sort is O(V + E) for V steps and E dependencies

### Security Considerations

- No sandboxing of executor functions
- API credentials passed through environment
- Need careful validation of external data

### Next Steps

1. **Parallel Execution**
   - Execute independent steps concurrently
   - Use promises/futures for async operations

2. **Better Error Recovery**
   - Retry logic for transient failures
   - Partial workflow recovery
   - Compensating transactions

3. **Workflow Persistence**
   - Save/load workflow definitions
   - Resume interrupted workflows
   - Audit trail of executions

4. **Visual Workflow Builder**
   - Generate workflow diagrams
   - Interactive workflow design
   - Real-time execution monitoring

### Lessons Learned

1. **Start with Simple Workflows**: Test basic flows before complex ones
2. **Clear Step Contracts**: Document inputs/outputs for each step type
3. **Error Visibility**: Comprehensive logging essential for debugging
4. **Composability**: Small, focused steps are easier to reuse