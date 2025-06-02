.PHONY: all clean topics readme json frequencies top20 stats help cleanall commit

# Config
REPO_LIMIT := 100
TOPICS_LIMIT := 20
DATA_DIR := data
MAKE := gmake

# Get current year and week for timestamped files
YEAR_WEEK := $(shell date +%Y-W%V)
REPOS_FILE := $(DATA_DIR)/repos-list-$(YEAR_WEEK).json
FREQ_FILE := $(DATA_DIR)/topic-frequencies-$(YEAR_WEEK).txt
TOP_FILE := $(DATA_DIR)/repos-top$(TOPICS_LIMIT)-$(YEAR_WEEK).txt

# Default target is help
.DEFAULT_GOAL := help

# Main build target
all: README.md ## Generate all files (complete rebuild)

# Create data directory if it doesn't exist
$(DATA_DIR): ## Create data directory if it doesn't exist
	@mkdir -p $(DATA_DIR)

# Primary data source - GitHub repository list as JSON (weekly timestamped)
$(REPOS_FILE): | $(DATA_DIR) ## Fetch repository data from GitHub API
	@echo "Fetching repository data for $(YEAR_WEEK)..."
	@gh repo list --visibility public --no-archived --limit $(REPO_LIMIT) --json name,description,repositoryTopics,url,createdAt,updatedAt > $@
	@echo "Repository data fetched to $@"

# Direct frequency count in standard format (weekly timestamped)
$(FREQ_FILE): $(REPOS_FILE) ## Generate topic frequency counts
	@echo "Generating topic frequency data for $(YEAR_WEEK)..."
	@jq -r '.[] | select(.repositoryTopics | length > 0) | .repositoryTopics[].name' $< | \
		sort | uniq -c | sort -nr > $@
	@echo "Topic frequency data generated at $@"

# Extract top N topics (weekly timestamped)
$(TOP_FILE): $(FREQ_FILE) ## Extract top N topics from frequency data
	@echo "Extracting top $(TOPICS_LIMIT) topics for $(YEAR_WEEK)..."
	@head -$(TOPICS_LIMIT) $< > $@
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
README.md: README.org topics.org ## Convert README.org to GitHub markdown
	@echo "Converting README.org to markdown..."
	@emacs --batch -l org --eval '(progn (find-file "README.org") (org-md-export-to-markdown) (kill-buffer))'
	@echo "README.md generated successfully!"

# Generate topic statistics 
stats: $(REPOS_FILE) $(FREQ_FILE) ## Display repository and topic statistics
	@echo "Generating repository statistics for $(YEAR_WEEK)..."
	@echo "Total repositories: $$(jq '. | length' $(REPOS_FILE))"
	@echo "Repositories with topics: $$(jq '[.[] | select(.repositoryTopics | length > 0)] | length' $(REPOS_FILE))"
	@echo "Total unique topics: $$(wc -l < $(FREQ_FILE))"
	@echo "Top 5 topics:"
	@head -5 $(FREQ_FILE)

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