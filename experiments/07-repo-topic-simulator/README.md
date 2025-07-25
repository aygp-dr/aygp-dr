# 07 - Repository Topic Generator Simulator

Simulate the complete flow of analyzing a repository and generating topics before building the final tool.

## Overview

This experiment:
- Simulates the control flow of topic generation
- Tests both shell and Scheme implementations
- Validates that our Scheme-heavy repo gets "scheme" as a topic
- Provides a testbed for the final CLI tool

## Components

- **simulator.scm**: Main simulation engine
- **github-client-v2.scm**: Pure Scheme GitHub client (no shell)
- **topic-generator.scm**: Topic generation workflow
- **test-flows/**: Different test scenarios

## Expected Outcome

Given this repository's content:
- Heavy Scheme code (.scm files)
- Experiments with Ollama integration
- GitHub API usage
- Validation frameworks

Should generate topics like:
- `scheme`
- `ollama`
- `github-api`
- `validation`
- `llm`
- `workflow-engine`

## Running the Simulation

```bash
make simulate
```