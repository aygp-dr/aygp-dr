#!/usr/bin/env bash
# Script to generate top 20 repository topics list

set -e

# Directory containing the script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# Root directory of repository
REPO_DIR="$(dirname "$SCRIPT_DIR")"
# Path to output file
OUTPUT_FILE="${REPO_DIR}/repos-top20.txt"

echo "Generating top 20 repository topics..."
gh repo list --visibility public --no-archived --limit 100 --json name,repositoryTopics | \
  jq -r '.[] | select(.repositoryTopics | length > 0) | .repositoryTopics[].name' | \
  sort | uniq -c | sort -nr | head -20 > "$OUTPUT_FILE"

echo "Top 20 repository topics saved to $OUTPUT_FILE"