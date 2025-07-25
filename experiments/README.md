# Experiments Directory

This directory contains experimental code and proof-of-concept implementations for various features.

## Current Experiments

### 01-ollama-structured-output/
Tests for Ollama's structured JSON output capabilities.

**Purpose**: Verify that Ollama can generate responses conforming to specific JSON schemas.

**Key Files**:
- `run-experiment.sh` - Complete test suite with health checks and validation
- `baseline-curl.sh` - Basic curl-based tests
- `README.md` - Detailed documentation and findings

**Running**:
```bash
cd 01-ollama-structured-output
./run-experiment.sh
```

### 02-ollama-structured-scheme/
Scheme implementation of Ollama structured output tests.

**Purpose**: Demonstrate making HTTP requests to Ollama from Guile Scheme.

**Key Files**:
- `ollama-structured.scm` - Guile Scheme implementation

**Status**: Ready for implementation after completing base experiment.

### 03-spec-json-conversion/
Bidirectional conversion between Scheme specifications and JSON schemas.

**Purpose**: Enable defining API schemas in Scheme and converting them to JSON Schema format.

**Key Files**:
- `spec-json-converter.scm` - Core conversion logic
- `example-schemas.scm` - Example schema definitions
- `README.md` - Format documentation

**Running**:
```bash
cd 03-spec-json-conversion
./spec-json-converter.scm
```

## Experiment Guidelines

1. Each experiment should be self-contained in its own directory
2. Include a README.md explaining the purpose and usage
3. Provide runnable examples and test cases
4. Document findings and conclusions
5. Clean up generated files with appropriate scripts

## Future Experiments

- GitHub GraphQL API exploration
- Repository topic recommendation using LLMs
- Automated documentation generation
- Multi-model comparison for structured output
- Performance benchmarking for API operations