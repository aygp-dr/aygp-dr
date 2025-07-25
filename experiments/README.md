# Experiments Directory

This directory contains experimental code and proof-of-concept implementations for various features.

## Experiment Overview

This directory contains 13 experiments exploring API integration patterns, validation frameworks, and tooling for Scheme-based API clients.

### Core API Experiments (01-04)
- **01-ollama-structured-output**: Ollama JSON output testing
- **02-ollama-structured-scheme**: Scheme Ollama client
- **03-spec-json-conversion**: Bidirectional schema conversion
- **04-github-api-integration**: GitHub REST client with rate limiting

### Infrastructure Experiments (05-09)
- **05-spec-validation-framework**: Runtime validation engine
- **06-api-composition**: Workflow composition patterns
- **07-error-handling**: Retry logic and fallback strategies
- **08-caching-layer**: LRU cache with TTL policies
- **09-config-management**: Environment-based configuration

### Quality & Operations (10-13)
- **10-integration-tests**: End-to-end pipeline testing
- **11-monitoring-observability**: Metrics and health checks
- **12-schema-evolution**: Version migration strategies
- **13-documentation-generation**: Auto-generated API docs

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