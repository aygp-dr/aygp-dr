#!/bin/bash
# validate-topics.sh - Validate that expected topics are generated

set -e

echo "=== Topic Generation Validation ==="
echo

# Expected topics for this repository
EXPECTED_TOPICS=(
    "scheme"
    "ollama"
    "github-api"
    "validation"
    "llm"
    "workflow"
    "api"
    "experiments"
)

echo "Expected topics for this repository:"
printf "  - %s\n" "${EXPECTED_TOPICS[@]}"
echo

# Run the simulator to generate topics
echo "Running topic generation simulation..."
GENERATED_TOPICS=$(guile simulator.scm 2>/dev/null | grep "Generated topics:" | sed 's/.*Generated topics: //' | tr -d '\n')

if [ -z "$GENERATED_TOPICS" ]; then
    echo "❌ Failed to generate topics"
    exit 1
fi

echo "Generated topics: $GENERATED_TOPICS"
echo

# Convert to arrays for comparison
IFS=', ' read -ra GENERATED_ARRAY <<< "$GENERATED_TOPICS"

# Check how many expected topics were found
FOUND_COUNT=0
TOTAL_EXPECTED=${#EXPECTED_TOPICS[@]}

echo "Validation results:"
for expected in "${EXPECTED_TOPICS[@]}"; do
    if [[ " ${GENERATED_ARRAY[*]} " =~ " ${expected} " ]]; then
        echo "  ✓ $expected - found"
        ((FOUND_COUNT++))
    else
        echo "  ✗ $expected - missing"
    fi
done

echo
echo "Summary:"
echo "  Found: $FOUND_COUNT/$TOTAL_EXPECTED expected topics"
echo "  Coverage: $(( FOUND_COUNT * 100 / TOTAL_EXPECTED ))%"

# Additional validation checks
echo
echo "Additional validation:"

# Check for minimum number of topics
GENERATED_COUNT=${#GENERATED_ARRAY[@]}
if [ "$GENERATED_COUNT" -ge 3 ]; then
    echo "  ✓ Generated sufficient topics ($GENERATED_COUNT)"
else
    echo "  ✗ Too few topics generated ($GENERATED_COUNT < 3)"
fi

# Check for valid GitHub topic format
INVALID_TOPICS=()
for topic in "${GENERATED_ARRAY[@]}"; do
    # Remove any trailing/leading whitespace
    topic=$(echo "$topic" | xargs)
    
    # Check GitHub topic format: lowercase, alphanumeric + hyphens, 1-50 chars
    if [[ ! "$topic" =~ ^[a-z0-9][a-z0-9-]*[a-z0-9]?$ ]] || [ ${#topic} -gt 50 ] || [ ${#topic} -lt 1 ]; then
        INVALID_TOPICS+=("$topic")
    fi
done

if [ ${#INVALID_TOPICS[@]} -eq 0 ]; then
    echo "  ✓ All topics follow GitHub format rules"
else
    echo "  ✗ Invalid topics found:"
    printf "    - %s\n" "${INVALID_TOPICS[@]}"
fi

# Overall result
echo
if [ "$FOUND_COUNT" -ge $((TOTAL_EXPECTED / 2)) ] && [ ${#INVALID_TOPICS[@]} -eq 0 ] && [ "$GENERATED_COUNT" -ge 3 ]; then
    echo "🎉 Validation PASSED - Topic generation working correctly"
    exit 0
else
    echo "❌ Validation FAILED - Topic generation needs improvement"
    exit 1
fi