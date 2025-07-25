# Spec-JSON Bidirectional Conversion Experiment

This experiment demonstrates bidirectional conversion between Scheme specifications and JSON schemas.

## Purpose

- Create a bridge between Scheme's natural list-based specifications and JSON Schema format
- Enable using Scheme to define schemas for Ollama and other JSON-based APIs
- Test round-trip conversion to ensure data integrity
- Provide a foundation for type-safe API interactions

## Specification Format

### Scheme Spec Format

```scheme
'((field-name . type-expression) ...)
```

### Supported Type Expressions

- **Basic Types**: `string`, `number`, `integer`, `boolean`, `null`
- **Arrays**: `(array type)`, `(array type min max)`
- **Objects**: `(object . nested-spec)`
- **Optional**: `(optional type)`
- **Union**: `(union type1 type2 ...)`
- **Enum**: `(enum "value1" "value2" ...)`
- **Constraints**: 
  - `(string-pattern "regex")`
  - `(number-range min max)`

## Examples

### Simple Object
```scheme
;; Scheme spec
'((name . string)
  (age . integer)
  (active . boolean))

;; Converts to JSON Schema
{
  "type": "object",
  "properties": {
    "name": {"type": "string"},
    "age": {"type": "integer"},
    "active": {"type": "boolean"}
  },
  "required": ["name", "age", "active"]
}
```

### Complex Structure
```scheme
;; Scheme spec
'((repository . string)
  (metadata . (object
              (description . string)
              (topics . (array string 3 20))
              (language . (enum "scheme" "python" "rust")))))

;; Converts to nested JSON Schema with constraints
```

## Running the Experiment

```bash
./spec-json-converter.scm
```

## Key Functions

- `spec->json-schema` - Convert Scheme spec to JSON Schema
- `json-schema->spec` - Convert JSON Schema back to Scheme spec
- `type-expr->json-schema` - Handle individual type expressions
- `extract-required-fields` - Determine required vs optional fields

## Integration with Ollama

The converter can generate schemas compatible with Ollama's structured output format:

```scheme
(define repo-spec
  '((repository . string)
    (description . string)
    (topics . (array string))))

;; Convert and use with Ollama API
(spec->json-schema repo-spec)
```

## Round-Trip Compatibility

The implementation ensures that schemas can survive round-trip conversion:
```scheme
spec -> JSON Schema -> spec -> JSON Schema
```

This is crucial for maintaining schema integrity across different systems.

## Future Enhancements

1. Support for `$ref` references
2. Additional constraint types (format, multipleOf, etc.)
3. Schema validation
4. Direct Ollama API integration
5. Schema composition and inheritance