.PHONY: run test-client test-rate test-pagination clean help check-token

# Default target
.DEFAULT_GOAL := help

# Check prerequisites
check-token: ## Check if GitHub token is set
	@if [ -z "$$GITHUB_TOKEN" ]; then \
		echo "Error: GITHUB_TOKEN environment variable not set"; \
		echo "Use: export GITHUB_TOKEN=your_token_here"; \
		exit 1; \
	else \
		echo "✓ GitHub token is set"; \
	fi

# Run all tests
run: check-token test-client test-rate test-pagination ## Run all GitHub API tests
	@echo ""
	@echo "✓ All GitHub API tests completed"

# Test basic client
test-client: check-token ## Test basic GitHub client functionality
	@echo "Testing GitHub client..."
	@chmod +x github-client.scm 2>/dev/null || true
	@guile github-client.scm

# Test rate limiting
test-rate: check-token ## Test rate limit handling
	@echo "Testing rate limit handling..."
	@chmod +x rate-limit-test.scm 2>/dev/null || true
	@guile rate-limit-test.scm

# Test pagination
test-pagination: check-token ## Test pagination handling
	@echo "Testing pagination..."
	@chmod +x pagination-test.scm 2>/dev/null || true
	@guile pagination-test.scm

# Clean generated files
clean: ## Clean any generated files
	@echo "Cleaning generated files..."
	@rm -f *.tmp *.log
	@echo "✓ Cleaned"

# Help
help: ## Display this help message
	@echo "GitHub API Integration Experiment"
	@echo "================================="
	@echo ""
	@echo "Prerequisites:"
	@echo "  export GITHUB_TOKEN=your_token_here"
	@echo ""
	@echo "Available targets:"
	@grep -E '^[a-zA-Z0-9_-]+:.*##' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*## "}; {printf "  %-15s - %s\n", $$1, $$2}'
	@echo ""
	@echo "Usage:"
	@echo "  make run           # Run all tests"
	@echo "  make test-client   # Test basic client"
	@echo "  make test-rate     # Test rate limiting"
	@echo "  make test-pagination # Test pagination"