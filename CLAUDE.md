# Project Guidelines

## Python Environment

- **Package manager**: uv — always run tools via `uv run` (e.g., `uv run pytest`, `uv run ruff check`)
- **Python version**: 3.12 (specified in `.python-version`)
- **Setup**: `make install` installs deps and configures git hooks

## Key Paths

- `src/<package>/` — application source
- `tests/unit/` — unit tests (no external dependencies)
- `tests/integration/` — integration tests (may require external services)
- `tests/fixtures/` — shared test data (CSV, JSON, etc.)

## Code Style

- **Line length**: 119 characters (Black + Ruff)
- **Formatter**: Black, targeting Python 3.12
- **Linter**: Ruff with rules: B, D, E, F, I, PLC0415, UP — do not add `noqa` suppressions
- **Docstrings**: Google-style on every module, public function, class, and method
- **Type checking**: MyPy with `warn_return_any` and `warn_unused_configs`

## Testing

- **Unit tests** (`tests/unit/`): fast, no external dependencies
- **Integration tests** (`tests/integration/`): marked with `@pytest.mark.integration`
- Use pytest fixtures, not `unittest.TestCase`
- Run unit tests: `make test`
- Run integration tests: `make test-integration`

## Development Workflow

1. `make install` — install dependencies and configure git hooks
2. Write code in `src/<package>/` and tests in `tests/`
3. `make check-all` — runs lint, format, typecheck, shellcheck, and unit tests
4. Commit — pre-commit hook enforces all checks automatically
