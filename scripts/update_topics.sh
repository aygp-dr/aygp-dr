#!/usr/bin/env bash
# Script to generate formatted repository topic list and update README.md
# Can be run on a cron job to keep topics up-to-date

set -e

# Directory containing the script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# Root directory of repository
REPO_DIR="$(dirname "$SCRIPT_DIR")"
# Path to README.md
README_PATH="${REPO_DIR}/README.md"
# Temporary files
TOPICS_RAW="${REPO_DIR}/repos-top10.txt"
TOPICS_MD="${REPO_DIR}/topics-top10.md"

# Generate topic list
echo "Generating topic list..."
gh repo list --visibility public --no-archived --limit 100 --json name,repositoryTopics | \
  jq -r '.[] | select(.repositoryTopics | length > 0) | .repositoryTopics[].name' | \
  sort | uniq -c | sort -nr | head -10 | tee "$TOPICS_RAW" | \
  awk '{ printf("[_%s_](https://github.com/search?q=topic%%3A%s&type=repositories)<sup><sub>%s</sub></sup>\n", $2, $2, $1);}' | \
  tee "$TOPICS_MD"

# Check if README exists
if [ ! -f "$README_PATH" ]; then
  echo "README.md not found at $README_PATH"
  exit 1
fi

# Update the topics section in README.md
echo "Updating README.md..."
awk -v topics="$(cat "$TOPICS_MD")" '
BEGIN { in_topics = 0; updated = 0; }
/^## Repository Topics/ { 
  in_topics = 1; 
  print; 
  print ""; 
  print topics; 
  updated = 1;
  next; 
}
in_topics && /^\[_.*_\]/ { next; } # Skip existing topic lines
in_topics && /^$/ && !updated { print topics; updated = 1; next; }
in_topics && /^[^[]/ { in_topics = 0; } # End of topics section
{ print; }
' "$README_PATH" > "${README_PATH}.new"

# Replace the old README with the new one
mv "${README_PATH}.new" "$README_PATH"

echo "README.md updated with latest topics!"

# To add this to cron, you can use:
# 0 0 * * * /path/to/update_topics.sh > /tmp/update_topics.log 2>&1