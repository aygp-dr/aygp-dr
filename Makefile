.PHONY: all clean topics readme json frequencies top20 stats help cleanall commit check-tools test-missing-tool test-delete-error test-strict-unset test-strict-error test-strict-pipefail test-dir-normal test-dir-order-only test-prereq-behavior test-precious test-override-vars test-override-cmds

# Delete targets if their recipe fails
.DELETE_ON_ERROR:

# Prevent directories from being deleted as intermediate files
.PRECIOUS: $(DATA_DIR)/ test-precious-dir/

# Use bash with strict error handling
SHELL := /usr/bin/env bash
.SHELLFLAGS := -euo pipefail -c

# User-configurable settings (can be overridden)
REPO_LIMIT ?= 100
TOPICS_LIMIT ?= 20
DATA_DIR ?= data

# Non-overridable settings
MAKE := gmake

# External commands
GH ?= gh
JQ ?= jq
SORT ?= sort
UNIQ ?= uniq
GREP ?= grep
HEAD ?= head
EMACS ?= emacs

# Get current year and week for timestamped files
YEAR_WEEK := $(shell date +%Y-W%V)
REPOS_FILE := $(DATA_DIR)/repos-list-$(YEAR_WEEK).json
FREQ_FILE := $(DATA_DIR)/topic-frequencies-$(YEAR_WEEK).txt
TOP_FILE := $(DATA_DIR)/repos-top$(TOPICS_LIMIT)-$(YEAR_WEEK).txt

# Default target is help
.DEFAULT_GOAL := help

# Main build target
all: README.md ## Generate all files (complete rebuild)

# Directory creation command
INSTALL_DIR := install -d

# Create data directory if it doesn't exist
$(DATA_DIR)/: ## Create data directory if it doesn't exist
	@$(INSTALL_DIR) $@

# Primary data source - GitHub repository list as JSON (weekly timestamped)
$(REPOS_FILE): | $(DATA_DIR)/ check-tools ## Fetch repository data from GitHub API
	@echo "Fetching repository data for $(YEAR_WEEK)..."
	@$(GH) repo list --visibility public --no-archived --limit $(REPO_LIMIT) --json name,description,repositoryTopics,url,createdAt,updatedAt > $@
	@echo "Repository data fetched to $@"

# Direct frequency count in standard format (weekly timestamped)
$(FREQ_FILE): $(REPOS_FILE) | $(DATA_DIR)/ ## Generate topic frequency counts
	@echo "Generating topic frequency data for $(YEAR_WEEK)..."
	@$(JQ) -r '.[] | select(.repositoryTopics | length > 0) | .repositoryTopics[].name' $< | \
		$(SORT) | $(UNIQ) -c | $(SORT) -nr > $@
	@echo "Topic frequency data generated at $@"

# Extract top N topics (weekly timestamped)
$(TOP_FILE): $(FREQ_FILE) | $(DATA_DIR)/ ## Extract top N topics from frequency data
	@echo "Extracting top $(TOPICS_LIMIT) topics for $(YEAR_WEEK)..."
	@$(HEAD) -$(TOPICS_LIMIT) $< > $@
	@echo "Top $(TOPICS_LIMIT) topics extracted to $@"

# Generate topics.org file from standard frequency format
topics.org: $(TOP_FILE) ## Format topics as org-mode with counts
	@echo "Generating org-mode topics file..."
	@echo "#+TITLE: Repository Topics" > $@
	@echo "#+OPTIONS: ^:{} toc:nil" >> $@
	@echo "" >> $@
	@echo "* Top GitHub Repository Topics" >> $@
	@echo "" >> $@
	@awk '{printf("[[https://github.com/search?q=topic%%3A%s&type=repositories][%s]]^{%s}\n", $$2, $$2, $$1)}' $< >> $@
	@echo "" >> $@
	@echo "Org-mode topics file generated at $@"

# Convert README.org to README.md
README.md: README.org topics.org check-tools ## Convert README.org to GitHub markdown
	@echo "Converting README.org to markdown..."
	@$(EMACS) --batch -l org --eval '(progn (find-file "README.org") (org-md-export-to-markdown) (kill-buffer))'
	@echo "README.md generated successfully!"

# Generate topic statistics 
stats: $(REPOS_FILE) $(FREQ_FILE) | $(DATA_DIR)/ check-tools ## Display repository and topic statistics
	@echo "Generating repository statistics for $(YEAR_WEEK)..."
	@echo "Total repositories: $$($(JQ) '. | length' $(REPOS_FILE))"
	@echo "Repositories with topics: $$($(JQ) '[.[] | select(.repositoryTopics | length > 0)] | length' $(REPOS_FILE))"
	@echo "Total unique topics: $$(wc -l < $(FREQ_FILE))"
	@echo "Top 5 topics:"
	@$(HEAD) -5 $(FREQ_FILE)

# Shortcut targets
topics: topics.org ## Shortcut for generating topics.org
readme: README.md ## Shortcut for generating README.md
json: $(REPOS_FILE) ## Shortcut for fetching repository data
frequencies: $(FREQ_FILE) ## Shortcut for generating frequency data
top20: $(TOP_FILE) ## Shortcut for extracting top topics

# Commit changes to GitHub (no CI)
commit: all ## Build and commit README.md with [skip ci]
	@echo "Committing README.md with [skip ci]..."
	@git add README.md
	@git commit -m "docs: update README with latest topics [skip ci]" -m "Update GitHub profile with current repository topics ($(YEAR_WEEK))"
	@git push origin main
	@echo "Changes committed and pushed to GitHub."

# Force rebuild
rebuild: clean all ## Force a clean rebuild of all files
	@echo "Rebuild complete!"

# Clean generated files for current week
clean: ## Remove files for current week only
	@echo "Cleaning generated files for $(YEAR_WEEK)..."
	@rm -f topics.org README.md $(REPOS_FILE) $(FREQ_FILE) $(TOP_FILE)
	@echo "Clean complete!"

# Clean all generated files
cleanall: ## Remove all generated files (all weeks)
	@echo "Cleaning all generated files..."
	@rm -f topics.org README.md $(DATA_DIR)/repos-list-*.json $(DATA_DIR)/topic-frequencies-*.txt $(DATA_DIR)/repos-top*.txt
	@echo "All clean complete!"

# Show help
help: ## Display this help message
	@echo "GitHub Profile README - Makefile Targets"
	@echo "========================================"
	@echo ""
	@echo "Usage: gmake [target]"
	@echo ""
	@echo "Available targets:"
	@grep -E '^[a-zA-Z0-9_.-]+:.*##' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*## "}; {printf "  %-15s - %s\n", $$1, $$2}'
	@echo ""
	@echo "Current week: $(YEAR_WEEK)"
	@echo "Example: gmake commit    # Build and commit with [skip ci]"

# Test target for .DELETE_ON_ERROR
test-delete-error: ## Test .DELETE_ON_ERROR functionality
	@echo "Cleaning up any previous test file..."
	@rm -f test-output.txt
	@echo "Creating test file..."
	@echo "This is a test file" > test-output.txt
	@echo "Now failing on purpose..."
	@non_existent_command_to_cause_error
	@echo "This should not be reached"

# Check for required tools
check-tools: ## Verify all required tools are installed
	@echo "Checking for required tools..."
	@command -v $(GH) >/dev/null 2>&1 || { echo "Error: GitHub CLI ($(GH)) is required but not installed"; exit 1; }
	@command -v $(JQ) >/dev/null 2>&1 || { echo "Error: jq ($(JQ)) is required but not installed"; exit 1; }
	@command -v $(EMACS) >/dev/null 2>&1 || { echo "Error: emacs ($(EMACS)) is required but not installed"; exit 1; }
	@echo "All required tools are installed"

# Test missing tool - this target simulates a missing tool for testing
test-missing-tool: ## Test behavior when a tool is missing
	@echo "Testing missing tool detection..."
	@command -v non_existent_tool >/dev/null 2>&1 || { echo "Error: non_existent_tool is required but not installed"; exit 1; }
	@echo "This should not be reached"

# Test order-only prerequisites
test-dir-normal: test-normal-dir ## Test normal directory prerequisite
	@echo "This target depends normally on test-normal-dir"
	@touch $@

test-dir-order-only: | test-order-only-dir ## Test order-only directory prerequisite
	@echo "This target depends on test-order-only-dir with order-only prereq"
	@touch $@

# Test helper to demonstrate order-only prerequisite behavior
test-prereq-behavior: ## Test and explain order-only prerequisite behavior
	@echo "Creating test directories and files..."
	@mkdir -p test-normal-dir test-order-only-dir
	@touch test-normal-dir test-order-only-dir
	@touch test-dir-normal test-dir-order-only
	@echo ""
	@echo "Step 1: All targets up to date"
	@echo "-----------------------------"
	@gmake -q test-dir-normal >/dev/null || echo "Normal prerequisite needs rebuild: Yes"; \
	if [ $$? -eq 0 ]; then echo "Normal prerequisite needs rebuild: No"; fi
	@gmake -q test-dir-order-only >/dev/null || echo "Order-only prerequisite needs rebuild: Yes"; \
	if [ $$? -eq 0 ]; then echo "Order-only prerequisite needs rebuild: No"; fi
	@echo ""
	@echo "Step 2: Touching prerequisite directories"
	@echo "-------------------------------------"
	@sleep 1
	@touch test-normal-dir test-order-only-dir
	@gmake -q test-dir-normal >/dev/null || echo "Normal prerequisite needs rebuild: Yes"; \
	if [ $$? -eq 0 ]; then echo "Normal prerequisite needs rebuild: No"; fi
	@gmake -q test-dir-order-only >/dev/null || echo "Order-only prerequisite needs rebuild: Yes"; \
	if [ $$? -eq 0 ]; then echo "Order-only prerequisite needs rebuild: No"; fi
	@echo ""
	@echo "Conclusion: Normal prerequisites trigger rebuilds when modified, order-only don't"

test-normal-dir:
	@mkdir -p $@
	@touch $@

test-order-only-dir:
	@mkdir -p $@
	@touch $@

# Test directory targets with .PRECIOUS
test-precious-dir/: ## Test creating a directory marked as .PRECIOUS
	@mkdir -p $@
	@touch $@
	@echo "Created precious directory: $@"

# Target to demonstrate .PRECIOUS behavior
test-precious: | test-precious-dir/ ## Test .PRECIOUS behavior
	@echo "This target depends on a precious directory"
	@echo "The directory won't be removed as an intermediate file"
	@echo "Demonstrating with 'find test-precious-dir -type f | wc -l':"
	@find test-precious-dir -type f 2>/dev/null | wc -l || echo "0 files"

# Test user-overridable variables
test-override-vars: ## Test user-overridable variables with ?= assignment
	@echo "Current variable values:"
	@echo "REPO_LIMIT = $(REPO_LIMIT)"
	@echo "TOPICS_LIMIT = $(TOPICS_LIMIT)"
	@echo "DATA_DIR = $(DATA_DIR)"
	@echo ""
	@echo "To override, run: make test-override-vars REPO_LIMIT=500"
	@echo "or: export REPO_LIMIT=500; make test-override-vars"

# Test command variables
test-override-cmds: ## Test command variable overrides
	@echo "Current command settings:"
	@echo "GH = $(GH)"
	@echo "JQ = $(JQ)"
	@echo "SORT = $(SORT)"
	@echo "HEAD = $(HEAD)"
	@echo ""
	@echo "To override, run: make test-override-cmds JQ=/usr/local/bin/jq"
	@echo "or: export JQ=/usr/local/bin/jq; make test-override-cmds"

# Test targets for SHELL flags
test-strict-unset: ## Test -u flag (unset variable detection)
	@echo "Testing unset variable detection..."
	@DEFINED_VAR=hello; echo "DEFINED_VAR=$${DEFINED_VAR}"
	@echo "UNDEFINED_VAR should cause an error:"
	@echo $${UNDEFINED_VAR}
	@echo "This should not be reached"

test-strict-error: ## Test -e flag (exit on error)
	@echo "Testing exit on error..."
	@echo "Running command that succeeds:"
	@echo "Hello world"
	@echo "Running command that fails:"
	@false
	@echo "This should not be reached"

test-strict-pipefail: ## Test -o pipefail (pipeline fails if any command fails)
	@echo "Testing pipeline failure handling..."
	@echo "Running pipeline with all successful commands:"
	@echo "Hello world" | grep Hello | wc -l
	@echo "Running pipeline with a failing command:"
	@echo "Hello world" | grep -q Nonexistent
	@echo "This should not be reached"