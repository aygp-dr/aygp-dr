# 02 - Ollama Structured Output in Scheme

Guile Scheme implementation of Ollama structured output testing.

## Overview

This experiment demonstrates:
- Making HTTP requests to Ollama from Guile Scheme
- Converting Scheme data structures to JSON
- Parsing Ollama responses
- Structured output validation

## Components

### ollama-structured.scm
Complete Scheme implementation featuring:
- HTTP client using curl via pipes
- JSON serialization from Scheme data
- Structured output schema definitions
- Test cases matching experiment 01

## Requirements

- Guile 3.0+
- Ollama running on localhost:11434
- curl (for HTTP requests)

## Usage

```bash
# Run the experiment
guile ollama-structured.scm

# Or with make
make run
```

## Features

1. **HTTP Client**: Uses `open-pipe*` to execute curl commands
2. **JSON Generation**: Custom `scm->json-string` converter
3. **Response Parsing**: Basic JSON response handling
4. **Error Handling**: Connection checking and error reporting
5. **Colored Output**: ANSI colors for better readability

## Test Cases

1. **Lean4 Analysis**: Complex nested structure
2. **Metadata Suggestions**: Repository metadata generation
3. **API Analysis**: GitHub API categorization

## Comparison with Experiment 01

This Scheme implementation mirrors the functionality of the bash/curl version but demonstrates:
- Native Scheme HTTP client patterns
- Data structure manipulation in Scheme
- Integration potential with other Scheme tools