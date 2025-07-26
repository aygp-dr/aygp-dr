# Experiment 08: JSON Parsing in Scheme

## Hypothesis
Guile Scheme likely has built-in or standard library JSON parsing capabilities that would be more robust than regex-based parsing for handling Ollama API responses.

## Baseline
Currently using regex-based parsing which is fragile and fails on:
- Escaped quotes in JSON strings
- Nested JSON structures
- Special characters in string values
- Proper type conversion (strings, numbers, booleans, null)

## Research Questions
1. Does Guile have a built-in JSON module?
2. What are the available JSON libraries for Guile?
3. How do they handle edge cases?
4. What's the performance impact?
5. Are they available in standard Guile installations?

## Initial Attempts

### 1. Regex-based parsing (current approach)
```scheme
(string-match "\"topics\":\\s*\\[([^\\]]+)\\]" response)
```
**Issues**: Fails on escaped characters, can't handle nested structures

### 2. Manual string parsing
```scheme
(regexp-substitute/global #f "\\\\\"" str 'pre "\"" 'post)
```
**Issues**: Complex, error-prone, incomplete

## Options to Explore

### Option 1: Guile-JSON (if available)
Check if `(json)` module exists in Guile

### Option 2: SRFI-180 JSON
Investigate if Guile supports SRFI-180 (JSON data interchange format)

### Option 3: Ice-9 JSON
Check if ice-9 library includes JSON support

### Option 4: External JSON library
Look for third-party Guile JSON libraries

### Option 5: Write minimal JSON parser
Create a simple but correct JSON parser for our specific use case

## Test Data
```json
{
  "model": "llama3.2:3b",
  "response": "{\"topics\": [\"scheme\", \"ollama\", \"github-api\", \"validation\", \"llm\"]}"
}
```

## Success Criteria
- Correctly parse nested JSON from Ollama API
- Handle escaped characters properly
- Convert to Scheme data structures (alists/lists)
- Work with standard Guile installation
- Minimal dependencies