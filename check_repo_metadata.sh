#!/usr/bin/env bash
# Script to check and suggest improvements for GitHub repository metadata
# Checks for description and topics in each repository

# Set colors for terminal output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo "Checking repository metadata for all aygp-dr projects..."
echo "============================================================"

for REPO_DIR in ~/projects/aygp-dr/*/; do
  # Skip if not a git directory
  if [ ! -d "$REPO_DIR/.git" ] && [ ! -f "$REPO_DIR/.git" ]; then
    continue
  fi
  
  REPO_NAME=$(basename "$REPO_DIR")
  echo -e "${GREEN}Repository: $REPO_NAME${NC}"
  
  # Change to repository directory
  cd "$REPO_DIR"
  
  # Check if repository is public
  VISIBILITY=$(gh repo view --json visibility --jq '.visibility' 2>/dev/null)
  
  if [ "$VISIBILITY" == "public" ]; then
    echo "Visibility: Public"
    
    # Get repository description
    DESCRIPTION=$(gh repo view --json description --jq '.description' 2>/dev/null)
    
    # Get repository topics
    TOPICS=$(gh repo view --json repositoryTopics --jq '.repositoryTopics[].name' 2>/dev/null)
    TOPIC_COUNT=$(echo "$TOPICS" | grep -v '^$' | wc -l)
    
    # Check description
    if [ -z "$DESCRIPTION" ]; then
      echo -e "${RED}⚠️ Missing description${NC}"
      echo "Suggested action: Add a clear description with 'gh repo edit --description \"Your description here\"'"
    elif [ ${#DESCRIPTION} -lt 20 ]; then
      echo -e "${YELLOW}⚠️ Description may be too short (${#DESCRIPTION} chars)${NC}: $DESCRIPTION"
      echo "Suggested action: Consider expanding the description with 'gh repo edit --description \"...\""
    else
      echo -e "Description (${#DESCRIPTION} chars): $DESCRIPTION"
    fi
    
    # Check topics
    if [ "$TOPIC_COUNT" -eq 0 ]; then
      echo -e "${RED}⚠️ Missing topics${NC}"
      echo "Suggested action: Add topics with 'gh repo edit --add-topic topic1,topic2,topic3'"
      
      # Generate Claude prompt for topic suggestions
      CLAUDE_PROMPT="This repository '$REPO_NAME' has description: '$DESCRIPTION'. Please suggest 3-5 relevant GitHub topics that would help categorize this repository. Format your response as a comma-separated list without explanations."
      echo -e "${YELLOW}Topic suggestions:${NC}"
      echo "$CLAUDE_PROMPT" | claude -p
    elif [ "$TOPIC_COUNT" -lt 3 ]; then
      echo -e "${YELLOW}⚠️ Only $TOPIC_COUNT topics:${NC} $TOPICS"
      echo "Suggested action: Consider adding more topics with 'gh repo edit --add-topic topic1,topic2'"
      
      # Generate Claude prompt for additional topic suggestions
      CLAUDE_PROMPT="This repository '$REPO_NAME' has description: '$DESCRIPTION' and current topics: [$TOPICS]. Please suggest 2-3 additional relevant GitHub topics that would help categorize this repository better. Format your response as a comma-separated list without explanations."
      echo -e "${YELLOW}Additional topic suggestions:${NC}"
      echo "$CLAUDE_PROMPT" | claude -p
    else
      echo -e "Topics ($TOPIC_COUNT): $TOPICS"
    fi
  else
    echo "Visibility: Private (skipping metadata check)"
  fi
  
  echo "============================================================"
done

echo "Metadata check complete!"