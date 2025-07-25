.PHONY: run test clean help

# Default target
.DEFAULT_GOAL := help

# Run the Scheme experiment
run: test ## Run the Ollama Scheme experiment
	@echo "Running Ollama structured output experiment (Scheme)..."
	@guile ollama-structured.scm

# Test prerequisites
test: ## Test Guile and Ollama availability
	@echo "Testing prerequisites..."
	@command -v guile >/dev/null 2>&1 || { echo "Error: Guile is required but not installed"; exit 1; }
	@echo "✓ Guile is installed: $$(guile --version | head -1)"
	@curl -s http://localhost:11434/api/tags >/dev/null 2>&1 && \
		echo "✓ Ollama is running" || \
		(echo "✗ Ollama is not running. Start with: ollama serve" && exit 1)

# Clean output files
clean: ## Clean generated output files
	@echo "Cleaning output directory..."
	@rm -rf output/
	@mkdir -p output/
	@echo "✓ Output directory cleaned"

# Debug Ollama connection
debug: test ## Debug Ollama connectivity
	@echo "Debugging Ollama connection..."
	@chmod +x debug-ollama.scm 2>/dev/null || true
	@guile debug-ollama.scm

# Run improved version
run-v2: test ## Run the improved version (v2)
	@echo "Running Ollama structured output experiment V2..."
	@chmod +x ollama-structured-v2.scm
	@guile ollama-structured-v2.scm

# Help
help: ## Display this help message
	@echo "Ollama Structured Scheme Experiment"
	@echo "==================================="
	@echo ""
	@echo "Available targets:"
	@grep -E '^[a-zA-Z0-9_-]+:.*##' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*## "}; {printf "  %-15s - %s\n", $$1, $$2}'
	@echo ""
	@echo "Usage:"
	@echo "  make run      # Run the Scheme experiment"
	@echo "  make run-v2   # Run improved version"
	@echo "  make debug    # Debug Ollama connection"
	@echo "  make test     # Check prerequisites"