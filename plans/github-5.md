# Plan for GitHub Issue #5 — Basic Authentication

Issue: https://github.com/dcbove-spoton/cosmostest/issues/5  
Outcome: **READY**  
Planning-attempt identifier: `30560303082`

<!-- cosmos-planner:v2 issue=5 todo-event=30560303082 outcome=READY -->

## Assessment

The expected behavior is clear, the affected FastAPI application and tests are identifiable, no new dependency is needed, and the work fits one pull request.

## Summary

Require HTTP Basic authentication across the application's API routes, initially accepting only the fixed username and password `test:test`, and document and test the protected behavior.

## Implementation plan

1. Update `src/cosmostest/main.py` to define a FastAPI HTTP Basic credential verifier, compare both credential fields safely, return a `401 Unauthorized` response with the Basic authentication challenge when credentials are absent or invalid, and register the verifier as an application-wide dependency so every API path operation is protected.
2. Expand `tests/unit/test_main.py` request helpers and coverage to verify that `/foo` rejects missing and incorrect credentials and continues returning its existing response when called with `test:test`; assert the expected authentication challenge on unauthorized responses.
3. Update `README.md` to state that API requests require HTTP Basic authentication and show the temporary development credentials in the `/foo` usage documentation.

## Testing

- Run `uv run pytest tests/unit/test_main.py` for focused authentication and endpoint coverage.
- Run `make check-all` to validate formatting, linting, type checking, shell checks, and the complete unit test suite.

## Risks and assumptions

- The fixed `test:test` credentials are intentionally temporary setup, not production secret management.
- “All methods” means all application API path operations, including routes added later through the globally configured dependency; generated framework documentation endpoints are outside that API-route scope.
- Unauthorized requests should use FastAPI's conventional `401` response and `WWW-Authenticate: Basic` challenge rather than a redirect or custom response body.
