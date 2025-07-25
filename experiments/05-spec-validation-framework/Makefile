.PHONY: run test-validator test-registry test-all examples clean help

# Default target
.DEFAULT_GOAL := help

# Run all tests
run: test-all examples ## Run complete validation framework tests

# Test validator core
test-validator: ## Test core validation engine
	@echo "Testing validation engine..."
	@chmod +x validator.scm 2>/dev/null || true
	@guile validator.scm

# Test spec registry
test-registry: ## Test spec registry functionality
	@echo "Testing spec registry..."
	@chmod +x spec-registry.scm 2>/dev/null || true
	@guile spec-registry.scm

# Run validation tests
test-all: ## Run all validation tests
	@echo "Running comprehensive validation tests..."
	@chmod +x validation-tests.scm 2>/dev/null || true
	@guile validation-tests.scm

# Run examples
examples: ## Run validation examples
	@echo "Running validation examples..."
	@for example in examples/*.scm; do \
		echo "Running $$example..."; \
		chmod +x $$example 2>/dev/null || true; \
		guile $$example || true; \
		echo ""; \
	done

# Clean generated files
clean: ## Clean any generated files
	@echo "Cleaning generated files..."
	@rm -f *.log *.tmp
	@echo "✓ Cleaned"

# Help
help: ## Display this help message
	@echo "Spec Validation Framework"
	@echo "========================"
	@echo ""
	@echo "Available targets:"
	@grep -E '^[a-zA-Z0-9_-]+:.*##' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*## "}; {printf "  %-15s - %s\n", $$1, $$2}'
	@echo ""
	@echo "Usage:"
	@echo "  make run          # Run all tests and examples"
	@echo "  make test-validator # Test core validator"
	@echo "  make test-registry  # Test spec registry"
	@echo "  make examples     # Run example validations"