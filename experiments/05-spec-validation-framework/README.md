# 05 - Spec Validation Framework

A comprehensive validation framework for API responses using Scheme specifications.

## Overview

This framework provides:
- Runtime validation of data against Scheme specs
- Detailed error reporting with paths
- Spec registry for reusable specifications
- Integration with API clients

## Components

### validator.scm
Core validation engine with:
- Type checking for all spec types
- Constraint validation (ranges, patterns, enums)
- Nested object/array validation
- Error path tracking

### spec-registry.scm
Central repository for:
- Spec registration and lookup
- Versioned specifications
- Cross-spec references
- Schema inheritance

### validation-tests.scm
Comprehensive test suite covering:
- All type expressions
- Edge cases and error conditions
- Performance benchmarks

### examples/
Real-world validation examples:
- Ollama response validation
- GitHub API response validation

## Usage

```scheme
;; Load the framework
(load "validator.scm")
(load "spec-registry.scm")

;; Register a spec
(register-spec 'user-spec 
  '((name . string)
    (age . (integer-range 0 150))
    (email . (string-pattern ".*@.*"))))

;; Validate data
(validate-data user-data 'user-spec)
```

## Error Reporting

Validation errors include:
- Path to the failing field
- Expected vs actual type
- Constraint violations
- Suggested fixes