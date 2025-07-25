# Experiment 05 Findings: Spec Validation Framework

## Date: 2025-07-25

### Key Learnings

1. **Guile Record Types**
   - Need to import `(srfi srfi-9)` for `define-record-type`
   - Records provide structured data with type safety
   - Predicates and accessors generated automatically

2. **Keyword Arguments**
   - Must use `define*` instead of `define` for keyword args
   - `#:key` syntax for named parameters
   - `#:optional` for optional positional parameters

3. **Pattern Matching**
   - `(ice-9 match)` provides powerful pattern matching
   - Can destructure complex nested structures
   - Handles multiple cases elegantly

4. **Hash Tables**
   - `(ice-9 hash-table)` for mutable key-value storage
   - Use `hash-set!` and `hash-ref` for operations
   - Good for registry/cache implementations

### Technical Achievements

1. **Core Validator**
   - Supports all basic types (string, number, integer, boolean, null)
   - Handles complex types (objects, arrays, unions, enums)
   - Constraint validation (patterns, ranges)
   - Path-based error reporting

2. **Spec Registry**
   - Central repository for reusable specifications
   - Versioning support for specs
   - Inheritance through `#:extends`
   - Cross-references with `(ref spec-name)`

3. **Error Reporting**
   - Detailed error paths (e.g., `user.contacts.0.value`)
   - Expected vs actual type information
   - Human-readable error messages
   - Multiple errors collected and reported

### Implementation Challenges

1. **Missing Standard Functions**
   - No built-in `iota` in base Guile
   - Had to implement custom indexed mapping
   - String manipulation functions limited

2. **Module Loading**
   - `(load "file.scm")` for local includes
   - Careful ordering of dependencies
   - Auto-compilation warnings common

3. **Type Checking**
   - Guile's dynamic typing requires explicit checks
   - Custom `type-of` function needed
   - Integer vs number distinction important

### Performance Notes

- Validation of 100-item dataset completed quickly
- Recursive validation handles deep nesting well
- No optimization needed for typical API responses

### Next Steps

1. **JSON Integration**
   - Add proper JSON parsing/generation
   - Validate actual API responses
   - Round-trip JSON ↔ Scheme data

2. **Advanced Features**
   - Custom validators
   - Async validation
   - Partial validation
   - Schema composition

3. **Error Recovery**
   - Suggest fixes for common errors
   - Auto-correction where possible
   - Better error messages

### Usage Examples

```scheme
;; Register a spec
(register-spec 'user-data
  '((id . integer)
    (email . (ref email))
    (roles . (array (enum "admin" "user")))))

;; Validate data
(validate-with-spec data 'user-data)
```

### Lessons Learned

1. **Start Simple**: Basic type validation first, then build up
2. **Test Early**: Each component tested independently
3. **Error Paths**: Critical for debugging validation failures
4. **Reusability**: Registry pattern enables spec sharing