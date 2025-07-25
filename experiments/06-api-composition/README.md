# 06 - API Composition

Compose multiple API calls into workflows using specs for validation.

## Overview

This experiment implements a workflow engine that can:
- Chain API calls with automatic data passing
- Transform data between different API formats
- Validate data at each step using specs
- Handle errors gracefully with detailed logging
- Support parallel and sequential execution paths

## Components

### Core Engine
- **workflow-engine.scm**: The main workflow execution engine
  - Step-based execution model
  - Dependency resolution with topological sorting
  - Extensible executor registry
  - Context management for state and errors

### API Integration
- **repo-analyzer.scm**: GitHub → Ollama analysis pipeline
  - Fetches GitHub repositories
  - Analyzes with Ollama AI
  - Generates comprehensive reports

### Example Workflows
- **workflows/code-review-workflow.scm**: Automated code review
- **workflows/data-pipeline-workflow.scm**: ETL-style data processing

## Architecture

```
Workflow
  ├── Steps (with dependencies)
  │   ├── API Call Step
  │   ├── Transform Step
  │   ├── Validate Step
  │   └── Merge Step
  └── Execution Context
      ├── Data Store (hash table)
      ├── Error Log
      └── Execution Log
```

## Built-in Step Types

1. **api-call**: Make HTTP API requests
2. **transform**: Transform data with custom functions
3. **validate**: Validate against registered specs
4. **merge**: Combine multiple data sources
5. **filter**: Filter data based on predicates

## Usage

### Basic Workflow
```scheme
(define workflow
  (create-workflow "my-workflow" "Description"
    (create-step 'fetch 'api-call 
                 '((endpoint . "/api/data")))
    (create-step 'process 'transform
                 `((input . fetch)
                   (transform . ,(lambda (data) 
                                  (process-data data))))
                 'fetch)))

(define result (execute-workflow workflow '()))
```

### Running Examples
```bash
# Test workflow engine
make test-engine

# Test repository analyzer  
make test-analyzer

# Run all workflow examples
make examples
```

## Key Features

- **Dependency Management**: Automatic execution ordering
- **Error Resilience**: Steps fail independently
- **Extensibility**: Easy to add new step types
- **Logging**: Comprehensive execution tracking
- **Validation**: Integration with spec framework

## Extending

To add a new step type:
```scheme
(define (my-executor step context)
  ;; Implementation
  result)

(register-step-executor 'my-type my-executor)
```