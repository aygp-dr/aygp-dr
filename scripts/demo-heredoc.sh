#!/bin/bash
# This script demonstrates the use of heredoc syntax for multi-line output

# Example with heredoc (preferred for complex multi-line output)
cat <<EOF
This output demonstrates the use of heredoc syntax for
multi-line text output in shell scripts.

Benefits:
  - Consistent formatting
  - Easier to maintain
  - Preserves whitespace exactly as written
  - Allows for easier block updates
  
The output above would require multiple echo statements
without heredoc syntax.
EOF

echo -e "\n--- Same output with multiple echo statements ---\n"

# Example with multiple echo statements (less maintainable)
echo "This output demonstrates the use of heredoc syntax for"
echo "multi-line text output in shell scripts."
echo ""
echo "Benefits:"
echo "  - Consistent formatting"
echo "  - Easier to maintain"
echo "  - Preserves whitespace exactly as written"
echo "  - Allows for easier block updates"
echo "  "
echo "The output above would require multiple echo statements"
echo "without heredoc syntax."