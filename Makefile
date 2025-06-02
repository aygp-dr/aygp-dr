.PHONY: all clean topics readme

# Main target
all: README.md

# Generate raw topic data
repos-top20.txt:
	@echo "Generating repository topic data..."
	@bash scripts/generate_repos-top20.sh

# Generate formatted org-mode topic list
topics.org: repos-top20.txt
	@echo "Generating org-mode topics file..."
	@bash scripts/generate_topics.sh

# Convert README.org to README.md
README.md: README.org topics.org
	@echo "Converting README.org to markdown..."
	@emacs --batch -l org --eval '(progn (find-file "README.org") (org-md-export-to-markdown) (kill-buffer))'
	@echo "README.md generated successfully!"

# Shortcut targets
topics: topics.org
readme: README.md

# Clean generated files
clean:
	@echo "Cleaning generated files..."
	@rm -f repos-top20.txt topics.org README.md
	@echo "Clean complete!"

# Show help
help:
	@echo "Available targets:"
	@echo "  all        - Generate all files (default)"
	@echo "  topics     - Generate topics.org file"
	@echo "  readme     - Generate README.md file"
	@echo "  clean      - Remove all generated files"