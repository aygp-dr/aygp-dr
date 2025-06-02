.PHONY: all clean topics readme json frequencies top20 stats help theory

# Config
REPO_LIMIT := 100
DATA_DIR := data
SCRIPTS_DIR := scripts
MAKE := gmake

# Default target is help
.DEFAULT_GOAL := help

# Main build target
all: README.md

# Create data directory if it doesn't exist
$(DATA_DIR):
	@mkdir -p $(DATA_DIR)

# Primary data source - GitHub repository list as JSON
$(DATA_DIR)/repos-list.json: | $(DATA_DIR)
	@echo "Fetching primary repository data..."
	@gh repo list --visibility public --no-archived --limit $(REPO_LIMIT) --json name,description,repositoryTopics,url,createdAt,updatedAt > $@
	@echo "Repository data fetched to $@"

# Direct frequency count in standard format (no intermediate JSON)
$(DATA_DIR)/topic-frequencies.txt: $(DATA_DIR)/repos-list.json
	@echo "Generating topic frequency data..."
	@jq -r '.[] | select(.repositoryTopics | length > 0) | .repositoryTopics[].name' $< | \
		sort | uniq -c | sort -nr > $@
	@echo "Topic frequency data generated at $@"

# Extract top 20 topics
$(DATA_DIR)/repos-top20.txt: $(DATA_DIR)/topic-frequencies.txt
	@echo "Extracting top 20 topics..."
	@head -20 $< > $@
	@echo "Top 20 topics extracted to $@"

# Generate topics.org file from standard frequency format
topics.org: $(DATA_DIR)/repos-top20.txt
	@echo "Generating org-mode topics file..."
	@echo "#+TITLE: Repository Topics" > $@
	@echo "#+OPTIONS: ^:{} toc:nil" >> $@
	@echo "" >> $@
	@awk '{printf("[[https://github.com/search?q=topic%%3A%s&type=repositories][%s]]^{%s}\n", $$2, $$2, $$1)}' $< >> $@
	@echo "Org-mode topics file generated at $@"

# Convert README.org to README.md
README.md: README.org topics.org
	@echo "Converting README.org to markdown..."
	@emacs --batch -l org --eval '(progn (find-file "README.org") (org-md-export-to-markdown) (kill-buffer))'
	@echo "README.md generated successfully!"

# Generate topic statistics 
stats: $(DATA_DIR)/repos-list.json $(DATA_DIR)/topic-frequencies.txt
	@echo "Generating repository statistics..."
	@echo "Total repositories: $$(jq '. | length' $(DATA_DIR)/repos-list.json)"
	@echo "Repositories with topics: $$(jq '[.[] | select(.repositoryTopics | length > 0)] | length' $(DATA_DIR)/repos-list.json)"
	@echo "Total unique topics: $$(wc -l < $(DATA_DIR)/topic-frequencies.txt)"
	@echo "Top 5 topics:"
	@head -5 $(DATA_DIR)/topic-frequencies.txt

# Show category theory / relational algebra mappings
theory:
	@echo "Category Theory / Relational Algebra in this Makefile:"
	@echo "1. Objects:"
	@echo "   - Repository list (repos-list.json) = Source object"
	@echo "   - Topic frequencies (topic-frequencies.txt) = Intermediate object"
	@echo "   - Topics list (topics.org) = Target object"
	@echo ""
	@echo "2. Morphisms (Transformations):"
	@echo "   - repos-list.json → topic-frequencies.txt = Projection + Aggregation"
	@echo "   - topic-frequencies.txt → repos-top20.txt = Selection (Head)"
	@echo "   - repos-top20.txt → topics.org = Formatting transformation"
	@echo ""
	@echo "3. Composition:"
	@echo "   - all: README.md ← README.org ← topics.org ← repos-top20.txt ← topic-frequencies.txt ← repos-list.json"
	@echo "   (This is function composition from category theory: f ∘ g ∘ h)"
	@echo ""
	@echo "4. Relational Operations:"
	@echo "   - Selection (σ): Filtering repos with topics and taking top 20"
	@echo "   - Projection (π): Extracting only topic names"
	@echo "   - Aggregation: Counting topic frequencies with sort | uniq -c"
	@echo "   - Format transformation: Converting to org-mode links"

# Shortcut targets
topics: topics.org
readme: README.md
json: $(DATA_DIR)/repos-list.json
frequencies: $(DATA_DIR)/topic-frequencies.txt
top20: $(DATA_DIR)/repos-top20.txt

# Clean generated files
clean:
	@echo "Cleaning generated files..."
	@rm -f topics.org README.md $(DATA_DIR)/repos-list.json $(DATA_DIR)/topic-frequencies.txt $(DATA_DIR)/repos-top20.txt
	@echo "Clean complete!"

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
	@echo "  top20        - Extract top 20 topics as text"
	@echo "  topics       - Generate topics.org file"
	@echo "  readme       - Generate README.md file"
	@echo "  stats        - Show repository statistics"
	@echo "  theory       - Show category theory / relational algebra mappings"
	@echo "  clean        - Remove all generated files"
	@echo ""
	@echo "Example: gmake all    # Rebuild everything"