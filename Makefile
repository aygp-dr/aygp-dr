.PHONY: all clean topics readme

# Config
REPO_LIMIT := 100
DATA_DIR := data
SCRIPTS_DIR := scripts

# Main target
all: README.md

# Create data directory if it doesn't exist
$(DATA_DIR):
	@mkdir -p $(DATA_DIR)

# Primary data source - GitHub repository list as JSON
$(DATA_DIR)/repos-list.json: | $(DATA_DIR)
	@echo "Fetching primary repository data..."
	@gh repo list --visibility public --no-archived --limit $(REPO_LIMIT) --json name,description,repositoryTopics,url,createdAt,updatedAt > $@
	@echo "Repository data fetched to $@"

# Algebraic projection: topic frequencies
$(DATA_DIR)/topic-frequencies.json: $(DATA_DIR)/repos-list.json
	@echo "Generating topic frequency data..."
	@jq -r '.[] | select(.repositoryTopics | length > 0) | .repositoryTopics[].name' $< | \
		sort | uniq -c | sort -nr | \
		jq -R -s 'split("\n") | map(select(length > 0) | ltrimstr(" ") | split(" ") | {count: .[0]|tonumber, topic: .[1]}) | sort_by(-.count)' > $@
	@echo "Topic frequency data generated at $@"

# Algebraic projection: top 20 topics as text
$(DATA_DIR)/repos-top20.txt: $(DATA_DIR)/topic-frequencies.json
	@echo "Extracting top 20 topics..."
	@jq -r '.[:20] | .[] | (.count|tostring) + " " + .topic' $< > $@
	@echo "Top 20 topics extracted to $@"

# Generate formatted org-mode topic list
topics.org: $(DATA_DIR)/topic-frequencies.json
	@echo "Generating org-mode topics file..."
	@cat > $@ << EOF
#+TITLE: Repository Topics
#+OPTIONS: ^:{} toc:nil

* Top GitHub Repository Topics

Current top topics across public repositories:

EOF
	@jq -r '.[:20] | .[] | "- [[https://github.com/search?q=topic%3A" + .topic + "&type=repositories][_" + .topic + "_]]^{" + (.count|tostring) + "}"' $< >> $@
	@cat >> $@ << 'EOF'

* Update Script
This source block can be executed to regenerate the topic list:

#+BEGIN_SRC sh :results output :var limit=20
gh repo list --visibility public --no-archived --limit 100 --json name,repositoryTopics | \
  jq -r '.[] | select(.repositoryTopics | length > 0) | .repositoryTopics[].name' | \
  sort | uniq -c | sort -nr | head -$$limit | \
  awk '{ printf("- [[https://github.com/search?q=topic%%3A%s&type=repositories][_%s_]]^{%s}\n", $$2, $$2, $$1);}'
#+END_SRC

* Repository Statistics

#+BEGIN_SRC sh :results output
gh repo list --visibility public --no-archived --limit 5 --json name,description,url | \
  jq -r '.[] | "- [[" + .url + "][" + .name + "]] - " + .description'
#+END_SRC
EOF
	@echo "Org-mode topics file generated at $@"

# Convert README.org to README.md
README.md: README.org topics.org
	@echo "Converting README.org to markdown..."
	@emacs --batch -l org --eval '(progn (find-file "README.org") (org-md-export-to-markdown) (kill-buffer))'
	@echo "README.md generated successfully!"

# Generate topic statistics in various formats
stats: $(DATA_DIR)/repos-list.json
	@echo "Generating repository statistics..."
	@echo "Total repositories: $$(jq '. | length' $<)"
	@echo "Repositories with topics: $$(jq '[.[] | select(.repositoryTopics | length > 0)] | length' $<)"
	@echo "Total unique topics: $$(jq -r '.[] | select(.repositoryTopics | length > 0) | .repositoryTopics[].name' $< | sort -u | wc -l)"
	@echo "Average topics per repository: $$(jq -r '[.[] | select(.repositoryTopics | length > 0) | .repositoryTopics | length] | add / length' $<)"

# Shortcut targets
topics: topics.org
readme: README.md
json: $(DATA_DIR)/repos-list.json
frequencies: $(DATA_DIR)/topic-frequencies.json
top20: $(DATA_DIR)/repos-top20.txt

# Clean generated files
clean:
	@echo "Cleaning generated files..."
	@rm -f topics.org README.md $(DATA_DIR)/repos-list.json $(DATA_DIR)/topic-frequencies.json $(DATA_DIR)/repos-top20.txt
	@echo "Clean complete!"

# Show help
help:
	@echo "Available targets:"
	@echo "  all          - Generate all files (default)"
	@echo "  json         - Fetch primary repository data"
	@echo "  frequencies  - Generate topic frequency data"
	@echo "  top20        - Extract top 20 topics as text"
	@echo "  topics       - Generate topics.org file"
	@echo "  readme       - Generate README.md file"
	@echo "  stats        - Show repository statistics"
	@echo "  clean        - Remove all generated files"