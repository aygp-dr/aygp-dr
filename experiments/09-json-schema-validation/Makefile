.PHONY: all capture validate test-validator check-tools clean

all: check-tools

capture: capture-llama-responses.sh
	@echo "=== Capturing Llama 3.2 responses ==="
	@./capture-llama-responses.sh

validate: validate-responses.scm
	@echo "=== Running validation examples ==="
	@guile validate-responses.scm

test-validator: json-validator.scm
	@echo "=== Testing JSON validator ==="
	@guile json-validator.scm

check-tools:
	@echo "=== Checking available validation tools ==="
	@echo -n "jq: "
	@which jq >/dev/null 2>&1 && echo "✓ installed" || echo "✗ not found"
	@echo -n "ajv: "
	@which ajv >/dev/null 2>&1 && echo "✓ installed" || echo "✗ not found (npm install -g ajv-cli)"
	@echo -n "jsonschema (Python): "
	@python3 -c "import jsonschema" 2>/dev/null && echo "✓ installed" || echo "✗ not found (pip install jsonschema)"
	@echo ""
	@echo "Recommended: jq for development, ajv for production"

test-jq-validation:
	@echo "=== Testing jq validation examples ==="
	@echo '{"model":"llama3.2:3b","response":"test","done":true}' | \
		jq 'if .model and .response and .done then "✓ Valid structure" else "✗ Invalid structure" end'
	@echo '{"response":"{\"topics\":[\"scheme\",\"lisp\"]}"}' | \
		jq -r '.response | fromjson | .topics[]' 2>/dev/null || echo "✗ Failed to parse topics"

install-ajv:
	@echo "Installing ajv-cli..."
	npm install -g ajv-cli

clean:
	rm -rf llama-responses/
	rm -f *.go