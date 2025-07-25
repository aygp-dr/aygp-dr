# Ollama Structured Output Experiment

This experiment tests Ollama's ability to generate structured JSON output according to provided schemas.

## Purpose

- Verify that Ollama can generate responses in a specific JSON format
- Test different complexity levels of structured output
- Create a baseline for comparison with other implementations (e.g., Scheme)
- Validate the approach for use in automated tools like the repository metadata checker

## Scripts

### baseline-curl.sh
Original curl-based tests focusing on three main scenarios:
1. Lean4 repository analysis
2. GitHub metadata suggestions
3. Complex API categorization

### run-experiment.sh
Complete experiment workflow including:
1. Health check - Verify Ollama is running
2. Model listing - Show available models
3. Model availability check - Ensure required model exists
4. Unstructured generation - Baseline test
5. Simple structured output - Basic JSON structure
6. Complex structured output - Nested objects and arrays
7. Validation - Check all outputs for validity

## Running the Experiment

```bash
# Make sure Ollama is running
ollama serve

# Run the complete experiment
./run-experiment.sh

# Or run just the baseline tests
./baseline-curl.sh
```

## Output Files

All outputs are saved to the `output/` directory:
- `models-list.json` - Available Ollama models
- `test-unstructured.json` - Basic generation response
- `test-structured-simple.json` - Simple structured output
- `test-structured-lean4.json` - Complex structured output
- `*-parsed.json` - Extracted and formatted structured content

## JSON Schema Format

Ollama accepts a `format` parameter that follows JSON Schema conventions:

```json
{
  "type": "object",
  "properties": {
    "field_name": {
      "type": "string",
      "maxLength": 100
    },
    "array_field": {
      "type": "array",
      "items": {
        "type": "string"
      }
    }
  },
  "required": ["field_name"]
}
```

## Key Findings

1. Ollama supports structured output through the `format` parameter
2. The model attempts to follow the schema but may not always be perfect
3. Complex nested structures are supported
4. Validation is important to ensure compliance

## Next Steps

- Implement the Scheme version in `../ollama-structured-scheme/`
- Use structured output for automated repository analysis
- Create reusable schemas for common tasks