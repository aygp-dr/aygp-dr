.PHONY: run test-engine test-analyzer examples clean help

# Default target
.DEFAULT_GOAL := help

# Run all tests
run: test-engine test-analyzer examples ## Run complete API composition tests

# Test workflow engine
test-engine: ## Test the workflow engine
	@echo "Testing workflow engine..."
	@chmod +x workflow-engine.scm 2>/dev/null || true
	@guile workflow-engine.scm

# Test repository analyzer
test-analyzer: ## Test GitHub-Ollama analyzer
	@echo "Testing repository analyzer..."
	@chmod +x repo-analyzer.scm 2>/dev/null || true
	@guile repo-analyzer.scm

# Run workflow examples
examples: ## Run example workflows
	@echo "Running workflow examples..."
	@for workflow in workflows/*.scm; do \
		if [ -f "$$workflow" ]; then \
			echo "Running $$workflow..."; \
			chmod +x "$$workflow" 2>/dev/null || true; \
			guile "$$workflow" || true; \
			echo ""; \
		fi; \
	done

# Clean generated files
clean: ## Clean any generated files
	@echo "Cleaning generated files..."
	@rm -f *.log *.tmp output/*
	@echo "✓ Cleaned"

# Help
help: ## Display this help message
	@echo "API Composition Experiment"
	@echo "=========================="
	@echo ""
	@echo "Available targets:"
	@grep -E '^[a-zA-Z0-9_-]+:.*##' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*## "}; {printf "  %-15s - %s\n", $$1, $$2}'
	@echo ""
	@echo "Usage:"
	@echo "  make run          # Run all tests"
	@echo "  make test-engine  # Test workflow engine"
	@echo "  make test-analyzer # Test repo analyzer"
	@echo "  make examples     # Run workflow examples"