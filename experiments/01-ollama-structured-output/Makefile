.PHONY: run clean test baseline help

# Default target
.DEFAULT_GOAL := help

# Main experiment runner
run: ## Run the complete experiment suite
	@echo "Running Ollama structured output experiment..."
	@./run-experiment.sh

# Run baseline curl tests only
baseline: ## Run baseline curl tests
	@echo "Running baseline curl tests..."
	@./baseline-curl.sh

# Test if Ollama is available
test: ## Test Ollama availability
	@echo "Testing Ollama connection..."
	@curl -s http://localhost:11434/api/tags >/dev/null 2>&1 && \
		echo "✓ Ollama is running" || \
		(echo "✗ Ollama is not running. Start with: ollama serve" && exit 1)

# Clean generated outputs
clean: ## Clean output directory
	@echo "Cleaning output directory..."
	@rm -rf output/
	@mkdir -p output/
	@echo "✓ Output directory cleaned"

# Help target
help: ## Display this help message
	@echo "Ollama Structured Output Experiment"
	@echo "==================================="
	@echo ""
	@echo "Available targets:"
	@grep -E '^[a-zA-Z0-9_-]+:.*##' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*## "}; {printf "  %-15s - %s\n", $$1, $$2}'
	@echo ""
	@echo "Usage:"
	@echo "  make run      # Run complete experiment"
	@echo "  make test     # Test Ollama connection"
	@echo "  make clean    # Clean output files"