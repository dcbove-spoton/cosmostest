# Plan for GitHub Issue #5 — Basic Authentication

Issue: https://github.com/dcbove-spoton/cosmostest/issues/5  
Outcome: **READY**  
Planning-attempt identifier: `30572603322`

<!-- cosmos-planner:v2 issue=5 todo-event=30572603322 outcome=READY -->

## Assessment

The expected behavior remains clear, the affected FastAPI application, unit tests, and documentation are identifiable, no new dependency is required, and the work fits one pull request. The lifecycle branch already contains a candidate implementation from the prior planning epoch and closed, unmerged pull request #7; it can be preserved and validated against the unchanged default-branch baseline rather than rewritten.

## Summary

Require HTTP Basic authentication across the application's API routes, initially accepting only the fixed username and password `test:test`, and document and test the protected behavior. Review and reuse the existing lifecycle-branch changes where they satisfy these requirements, adding only necessary follow-up corrections.

## Implementation plan

1. Review the existing `src/cosmostest/main.py` changes against `main`; retain or adjust the HTTP Basic credential verifier so it safely validates both credential fields, returns `401 Unauthorized` with a Basic authentication challenge for absent or invalid credentials, and remains registered as an application-wide dependency protecting every API path operation.
2. Review and expand `tests/unit/test_main.py` so `/foo` coverage verifies missing credentials, invalid usernames and passwords, the authentication challenge on unauthorized responses, and the unchanged successful response with `test:test`.
3. Review `README.md` and retain or refine the API and `/foo` usage guidance so it clearly documents the temporary HTTP Basic requirement and development credentials.
4. Keep the prior implementation commit intact on `cosmos/github-5`; make any required corrections as new commits so the new delivery remains traceable and can supersede the closed, unmerged pull request without rewriting branch history.

## Testing

- Run `uv run pytest tests/unit/test_main.py` for focused authentication and endpoint coverage.
- Run `make check-all` to validate formatting, linting, type checking, shell checks, and the complete unit test suite.

## Risks and assumptions

- The fixed `test:test` credentials are intentionally temporary setup, not production secret management.
- “All methods” means all application API path operations, including routes added later through the globally configured dependency; generated framework documentation endpoints are outside that API-route scope.
- Unauthorized requests should use FastAPI's conventional `401` response and `WWW-Authenticate: Basic` challenge rather than a redirect or custom response body.
- The prior implementation is unmerged candidate work and must be validated before reuse; closed pull request #7 does not itself deliver the issue.
