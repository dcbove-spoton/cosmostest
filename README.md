# Python Project Template

Minimal Python project template with modern tooling: UV, Black, Ruff, Mypy, Pytest.

## Quick Start

1. Click **Use this template** on GitHub
2. Clone your new repo
3. Rename `src/cosmostest/` to `src/<yourapp>/` and update `pyproject.toml` (`name` and `[project.scripts]`)
4. `make install`
5. `make run`
6. Run `curl --user test:test http://localhost:8000/foo` to receive `"bar"`

## API

`make run` starts the FastAPI server at `http://localhost:8000`. All API requests require HTTP Basic authentication
using the temporary development credentials `test:test`.

| Method | Path | Response |
| --- | --- | --- |
| GET | `/foo` | `"bar"` |

## Prerequisites

```bash
# Install pyenv and Python 3.12
brew install pyenv
pyenv install 3.12
pyenv global 3.12

# Install UV
brew install uv
```

## Development Commands

```bash
make install          # Install dependencies and configure git hooks
make run              # Run the application
make lint             # Lint with ruff (auto-fix)
make format           # Format with black
make typecheck        # Type check with mypy
make test             # Run unit tests
make test-integration # Run integration tests
make check-all        # Run all checks
make clean            # Remove cache files
```

## Project Structure

```
├── src/<package>/       # Application code
│   ├── __init__.py
│   └── main.py          # Entry point
├── tests/
│   ├── unit/            # Unit tests
│   ├── integration/     # Integration tests
│   ├── fixtures/        # Test data
│   └── conftest.py      # Shared fixtures
├── .githooks/           # Pre-commit hook (lint, format, typecheck, test)
├── .claude/             # Claude Code config (permissions, statusline)
├── pyproject.toml       # Project config & dependencies
├── Makefile             # Development commands
├── CLAUDE.md            # Claude Code project guidelines
└── uv.lock              # Locked dependencies
```

## Adding Dependencies

Edit `pyproject.toml`:

```toml
dependencies = [
    "requests>=2.31.0",
]
```

Then run `make install`.

## License

MIT
