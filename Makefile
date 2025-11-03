.PHONY: test lint format check clean

# Run tests with plenary
test:
	@./scripts/test.sh

# Run lua-language-server linter
lint:
	@echo "Running lua-language-server..."
	@lua-language-server --check .

# Format code with stylua
format:
	@echo "Formatting with stylua..."
	@stylua lua/ tests/ plugin/

# Check formatting without modifying files
check:
	@echo "Checking formatting..."
	@stylua --check lua/ tests/ plugin/

# Run all checks (lint + format check + test)
ci: check lint test
	@echo "All checks passed!"

# Clean temporary files
clean:
	@rm -rf .tests/
	@find . -type f -name "*.swp" -delete
	@find . -type f -name "*.swo" -delete

help:
	@echo "Available targets:"
	@echo "  test    - Run tests with plenary.nvim"
	@echo "  lint    - Run lua-language-server linter"
	@echo "  format  - Format code with stylua"
	@echo "  check   - Check code formatting"
	@echo "  ci      - Run all checks (for CI)"
	@echo "  clean   - Remove temporary files"
