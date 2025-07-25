.PHONY: simulate test-github test-ollama validate clean help

# Default target
.DEFAULT_GOAL := help

# Run complete simulation
simulate: ## Run the complete topic generation simulation
	@echo "Running repository topic generation simulation..."
	@chmod +x simulator.scm 2>/dev/null || true
	@guile simulator.scm

# Test GitHub client
test-github: ## Test pure Scheme GitHub client
	@echo "Testing Scheme GitHub client..."
	@chmod +x github-client-v2.scm 2>/dev/null || true
	@guile github-client-v2.scm

# Test Ollama integration
test-ollama: ## Test Ollama topic generation
	@echo "Testing Ollama topic generation..."
	@chmod +x topic-generator.scm 2>/dev/null || true
	@guile topic-generator.scm

# Validate expected topics
validate: ## Validate that expected topics are generated
	@echo "Validating topic generation for current repo..."
	@./validate-topics.sh

# Clean generated files
clean: ## Clean simulation output
	@echo "Cleaning simulation files..."
	@rm -f *.log *.tmp simulation-output.json
	@echo "✓ Cleaned"

# Help
help: ## Display this help message
	@echo "Repository Topic Generator Simulator"
	@echo "===================================="
	@echo ""
	@echo "Available targets:"
	@grep -E '^[a-zA-Z0-9_-]+:.*##' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*## "}; {printf "  %-15s - %s\n", $$1, $$2}'
	@echo ""
	@echo "Usage:"
	@echo "  make simulate     # Run complete simulation"
	@echo "  make test-github  # Test GitHub client"
	@echo "  make test-ollama  # Test topic generation"
	@echo "  make validate     # Validate expected topics"