.PHONY: run test clean help

# Default target
.DEFAULT_GOAL := help

# Run the spec-json converter
run: test ## Run the spec-json conversion experiment
	@echo "Running spec-json conversion experiment..."
	@guile spec-json-converter.scm

# Test prerequisites
test: ## Test Guile availability and permissions
	@echo "Testing prerequisites..."
	@command -v guile >/dev/null 2>&1 || { echo "Error: Guile is required but not installed"; exit 1; }
	@echo "✓ Guile is installed: $$(guile --version | head -1)"
	@test -x spec-json-converter.scm || chmod +x spec-json-converter.scm
	@echo "✓ Script is executable"

# Run example schemas
examples: test ## Run example schema conversions
	@echo "Running example schema conversions..."
	@guile example-schemas.scm

# Clean output files
clean: ## Clean any generated files
	@echo "Cleaning generated files..."
	@rm -f *.tmp *.out
	@echo "✓ Cleaned"

# Help
help: ## Display this help message
	@echo "Spec-JSON Conversion Experiment"
	@echo "==============================="
	@echo ""
	@echo "Available targets:"
	@grep -E '^[a-zA-Z0-9_-]+:.*##' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*## "}; {printf "  %-15s - %s\n", $$1, $$2}'
	@echo ""
	@echo "Usage:"
	@echo "  make run      # Run the main converter"
	@echo "  make examples # Run example schemas"
	@echo "  make test     # Check prerequisites"