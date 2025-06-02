#!/usr/bin/env bash
# Script to generate formatted org-mode topic list

set -e

# Directory containing the script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# Root directory of repository
REPO_DIR="$(dirname "$SCRIPT_DIR")"
# Input file with raw topic data
INPUT_FILE="${REPO_DIR}/repos-top20.txt"
# Output org file
OUTPUT_FILE="${REPO_DIR}/topics.org"

if [ ! -f "$INPUT_FILE" ]; then
  echo "Error: Input file $INPUT_FILE not found"
  echo "Run scripts/generate_repos-top20.sh first"
  exit 1
fi

echo "Generating org-mode topics file..."

# Create org file header
cat > "$OUTPUT_FILE" << EOF
#+TITLE: Repository Topics
#+OPTIONS: ^:{} toc:nil

* Top GitHub Repository Topics

Current top topics across public repositories:

EOF

# Add formatted topics
cat "$INPUT_FILE" | awk '{ printf("- [[https://github.com/search?q=topic%%3A%s&type=repositories][_%s_]]^{%s}\n", $2, $2, $1);}' >> "$OUTPUT_FILE"

# Add source block for updating
cat >> "$OUTPUT_FILE" << 'EOF'

* Update Script
This source block can be executed to regenerate the topic list:

#+BEGIN_SRC sh :results output
gh repo list --visibility public --no-archived --limit 100 --json name,repositoryTopics | \
  jq -r '.[] | select(.repositoryTopics | length > 0) | .repositoryTopics[].name' | \
  sort | uniq -c | sort -nr | head -20 | \
  awk '{ printf("- [[https://github.com/search?q=topic%%3A%s&type=repositories][_%s_]]^{%s}\n", $2, $2, $1);}'
#+END_SRC
EOF

echo "Org-mode topics file saved to $OUTPUT_FILE"