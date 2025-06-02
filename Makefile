.PHONY: all clean topics readme json frequencies top20 stats help

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
all: README.md

# Create data directory if it doesn't exist
$(DATA_DIR):
	@mkdir -p $(DATA_DIR)

# Primary data source - GitHub repository list as JSON (weekly timestamped)
$(REPOS_FILE): | $(DATA_DIR)
	@echo "Fetching repository data for $(YEAR_WEEK)..."
	@gh repo list --visibility public --no-archived --limit $(REPO_LIMIT) --json name,description,repositoryTopics,url,createdAt,updatedAt > $@
	@echo "Repository data fetched to $@"

# Direct frequency count in standard format (weekly timestamped)
$(FREQ_FILE): $(REPOS_FILE)
	@echo "Generating topic frequency data for $(YEAR_WEEK)..."
	@jq -r '.[] | select(.repositoryTopics | length > 0) | .repositoryTopics[].name' $< | \
		sort | uniq -c | sort -nr > $@
	@echo "Topic frequency data generated at $@"

# Extract top N topics (weekly timestamped)
$(TOP_FILE): $(FREQ_FILE)
	@echo "Extracting top $(TOPICS_LIMIT) topics for $(YEAR_WEEK)..."
	@head -$(TOPICS_LIMIT) $< > $@
	@echo "Top $(TOPICS_LIMIT) topics extracted to $@"

# Generate topics.org file from standard frequency format
topics.org: $(TOP_FILE)
	@echo "Generating org-mode topics file..."
	@echo "#+TITLE: Repository Topics" > $@
	@echo "#+OPTIONS: ^:{} toc:nil" >> $@
	@echo "" >> $@
	@echo "* Top GitHub Repository Topics ($(YEAR_WEEK))" >> $@
	@echo "" >> $@
	@awk '{printf("[[https://github.com/search?q=topic%%3A%s&type=repositories][%s]]^{%s}\n", $$2, $$2, $$1)}' $< >> $@
	@echo "Org-mode topics file generated at $@"

# Convert README.org to README.md
README.md: README.org topics.org
	@if [ -f "$@" ] && [ ! -z "$$(find topics.org -newer "$@" 2>/dev/null)" ]; then \
		echo "Converting README.org to markdown..."; \
		emacs --batch -l org --eval '(progn (find-file "README.org") (org-md-export-to-markdown) (kill-buffer))'; \
		echo "README.md generated successfully!"; \
	elif [ ! -f "$@" ]; then \
		echo "README.md doesn't exist. Creating..."; \
		emacs --batch -l org --eval '(progn (find-file "README.org") (org-md-export-to-markdown) (kill-buffer))'; \
		echo "README.md generated successfully!"; \
	else \
		echo "README.md is up-to-date. No rebuild needed."; \
	fi

# Generate topic statistics 
stats: $(REPOS_FILE) $(FREQ_FILE)
	@echo "Generating repository statistics for $(YEAR_WEEK)..."
	@echo "Total repositories: $$(jq '. | length' $(REPOS_FILE))"
	@echo "Repositories with topics: $$(jq '[.[] | select(.repositoryTopics | length > 0)] | length' $(REPOS_FILE))"
	@echo "Total unique topics: $$(wc -l < $(FREQ_FILE))"
	@echo "Top 5 topics:"
	@head -5 $(FREQ_FILE)

# Shortcut targets
topics: topics.org
readme: README.md
json: $(REPOS_FILE)
frequencies: $(FREQ_FILE) 
top20: $(TOP_FILE)

# Clean generated files for current week
clean:
	@echo "Cleaning generated files for $(YEAR_WEEK)..."
	@rm -f topics.org README.md $(REPOS_FILE) $(FREQ_FILE) $(TOP_FILE)
	@echo "Clean complete!"

# Clean all generated files
cleanall:
	@echo "Cleaning all generated files..."
	@rm -f topics.org README.md $(DATA_DIR)/repos-list-*.json $(DATA_DIR)/topic-frequencies-*.txt $(DATA_DIR)/repos-top*.txt
	@echo "All clean complete!"

# Show help
help:
	@echo "GitHub Topic Pipeline - Makefile Targets"
	@echo "========================================"
	@echo ""
	@echo "Usage: gmake [target]"
	@echo ""
	@echo "Available targets:"
	@echo "  help         - Show this help message (default)"
	@echo "  all          - Generate all files (complete rebuild)"
	@echo "  json         - Fetch primary repository data"
	@echo "  frequencies  - Generate topic frequency data"
	@echo "  top20        - Extract top $(TOPICS_LIMIT) topics as text"
	@echo "  topics       - Generate topics.org file"
	@echo "  readme       - Generate README.md file"
	@echo "  stats        - Show repository statistics"
	@echo "  clean        - Remove files for current week ($(YEAR_WEEK))"
	@echo "  cleanall     - Remove all generated files"
	@echo ""
	@echo "Current week: $(YEAR_WEEK)"
	@echo "Example: gmake all    # Rebuild everything"