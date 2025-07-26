.PHONY: all run test-options test-custom test-ollama clean

all: run

run: test-options

test-options:
	@echo "=== Testing JSON parsing options in Guile ==="
	@guile test-json-options.scm || true

test-custom: custom-json-parser.scm
	@echo "=== Testing custom JSON parser ==="
	@guile custom-json-parser.scm

test-samples: test-with-samples.scm
	@echo "=== Testing with sample files ==="
	@guile test-with-samples.scm

test-proper: json-parser-proper.scm
	@echo "=== Testing proper JSON parsing methods ==="
	@guile json-parser-proper.scm

test-ollama: test-ollama-json.scm
	@echo "=== Testing Ollama JSON parsing ==="
	@guile test-ollama-json.scm

check-libs:
	@echo "=== Checking for JSON libraries ==="
	@echo "Checking system packages..."
	@which guile | head -1
	@guile --version | head -1
	@echo ""
	@echo "Checking for guile-json package:"
	@pkg-config --exists guile-json && echo "✓ guile-json found" || echo "✗ guile-json not found"
	@echo ""
	@echo "Available through package manager:"
	@echo "  FreeBSD: pkg install guile-json"
	@echo "  Debian/Ubuntu: apt install guile-json"
	@echo "  macOS: brew install guile-json"

install-guile-json:
	@echo "Attempting to install guile-json..."
	@if command -v pkg >/dev/null 2>&1; then \
		echo "FreeBSD detected, run: sudo pkg install guile-json"; \
	elif command -v apt >/dev/null 2>&1; then \
		echo "Debian/Ubuntu detected, run: sudo apt install guile-json"; \
	elif command -v brew >/dev/null 2>&1; then \
		echo "macOS detected, run: brew install guile-json"; \
	else \
		echo "Package manager not detected"; \
	fi

clean:
	rm -f *.go