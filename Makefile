.PHONY: lint format typecheck shellcheck test test-integration check-all run install clean help

# Linting and formatting
lint:
	uv run ruff check src/ tests/ --fix

format:
	uv run black src/ tests/

typecheck:
	uv run mypy src/ tests/unit/ tests/integration/

shellcheck:
	@find .githooks -type f \( -name '*.sh' -o -name 'pre-commit' \) -print0 | xargs -0 shellcheck -x --source-path=SCRIPTDIR

test:
	uv run pytest tests/unit/ -v -m "not integration" || test $$? -eq 5

test-integration:
	uv run pytest tests/integration/ -v -m integration || test $$? -eq 5

check-all: lint format typecheck shellcheck test
	@echo "✅ All checks passed!"

# Development
install:
	uv sync --dev
	git config core.hooksPath .githooks

run:
	uv run cosmostest

# Cleanup
clean:
	find . -type f -name "*.pyc" -delete
	find . -type d -name "__pycache__" -delete
	find . -type d -name ".mypy_cache" -exec rm -rf {} +
	find . -type d -name ".pytest_cache" -exec rm -rf {} +

# Help
help:
	@echo "Available commands:"
	@echo "  make install          - Install dependencies and configure git hooks"
	@echo "  make lint             - Run ruff linter (with auto-fix)"
	@echo "  make format           - Format code with black"
	@echo "  make typecheck        - Run mypy type checker"
	@echo "  make shellcheck       - Lint shell scripts under .githooks/"
	@echo "  make test             - Run unit tests with pytest"
	@echo "  make test-integration - Run integration tests"
	@echo "  make check-all        - Run all checks (lint, format, typecheck, test)"
	@echo "  make run              - Run the application"
	@echo "  make clean            - Clean up cache files"
	@echo "  make help             - Show this help"
