#!/usr/bin/env bash
# Script to check and suggest improvements for GitHub repository metadata
# Uses GitHub API directly without requiring local filesystem access

# Set colors for terminal output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Get authenticated user
USER=$(gh api user --jq .login)

echo "Checking repository metadata for $USER..."
echo "============================================================"

# Get all public repositories for the user
gh repo list "$USER" --visibility public --no-archived --limit 100 --json name,description,visibility,repositoryTopics | \
jq -r '.[] | @json' | while IFS= read -r repo_json; do
  # Parse repository data
  REPO_NAME=$(echo "$repo_json" | jq -r '.name')
  DESCRIPTION=$(echo "$repo_json" | jq -r '.description // ""')
  TOPICS=$(echo "$repo_json" | jq -r '.repositoryTopics[].name' 2>/dev/null)
  TOPIC_COUNT=$(echo "$repo_json" | jq -r '.repositoryTopics | length')
  
  echo -e "${GREEN}Repository: $REPO_NAME${NC}"
  echo "Visibility: Public"
  
  # Check description
  if [ -z "$DESCRIPTION" ] || [ "$DESCRIPTION" = "null" ]; then
    echo -e "${RED}⚠️ Missing description${NC}"
    echo "Suggested action: gh repo edit $USER/$REPO_NAME --description \"Your description here\""
  elif [ ${#DESCRIPTION} -lt 20 ]; then
    echo -e "${YELLOW}⚠️ Description may be too short (${#DESCRIPTION} chars)${NC}: $DESCRIPTION"
    echo "Suggested action: gh repo edit $USER/$REPO_NAME --description \"...\""
  else
    echo -e "Description (${#DESCRIPTION} chars): $DESCRIPTION"
  fi
  
  # Check topics
  if [ "$TOPIC_COUNT" -eq 0 ]; then
    echo -e "${RED}⚠️ Missing topics${NC}"
    echo "Suggested action: gh repo edit $USER/$REPO_NAME --add-topic topic1,topic2,topic3"
    
    # Provide generic suggestions based on common patterns
    echo -e "${YELLOW}Common topic suggestions based on repo name:${NC}"
    case "$REPO_NAME" in
      *-py|*python*) echo "  python, python3, python-library" ;;
      *-js|*javascript*) echo "  javascript, nodejs, npm" ;;
      *-rs|*rust*) echo "  rust, cargo, rust-lang" ;;
      *-go|*golang*) echo "  go, golang, go-module" ;;
      *-scheme|*scm*) echo "  scheme, lisp, functional-programming" ;;
      *-clj|*clojure*) echo "  clojure, clojurescript, jvm" ;;
      *-ml|*ai*) echo "  machine-learning, ai, artificial-intelligence" ;;
      *-api*) echo "  api, rest-api, web-api" ;;
      *-cli*) echo "  cli, command-line, terminal" ;;
      *) echo "  Consider adding language and purpose-specific topics" ;;
    esac
  elif [ "$TOPIC_COUNT" -lt 3 ]; then
    echo -e "${YELLOW}⚠️ Only $TOPIC_COUNT topics:${NC}"
    echo "$TOPICS" | tr '\n' ' '
    echo ""
    echo "Suggested action: gh repo edit $USER/$REPO_NAME --add-topic topic1,topic2"
  else
    echo -e "Topics ($TOPIC_COUNT):"
    echo "$TOPICS" | tr '\n' ' '
    echo ""
  fi
  
  echo "============================================================"
done

echo "Metadata check complete!"
echo ""
echo "Summary of GitHub REST API endpoints used:"
echo "  - GET /user - Get authenticated user"
echo "  - GET /users/{user}/repos - List user repositories"
echo "  - PATCH /repos/{owner}/{repo} - Edit repository (for fixing issues)"