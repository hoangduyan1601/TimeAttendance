# Portfolio Audit — Hardening Round 2

## Score history

- Initial audit: 42/100
- Previous hardened state: 78/100
- Current assessment: 88/100

## Round-two changes

- Serialized same-employee attendance writes with a transaction and pessimistic user-row lock.
- Reject duplicate/complete/inconsistent daily attendance with 409 and added regression tests.
- Protected kiosk routes with a rotatable environment-backed `X-Kiosk-Key` using constant-time comparison.
- Removed an unused hard-coded AES key utility.
- Required reset for non-BCrypt legacy accounts without plaintext fallback; added a migration runbook.
- Added Java-to-AI connection/response timeouts.
- Added AI MIME, 5 MB size, empty/decode/base64 validation and generic internal-error responses.
- Added seven FastAPI behavior/security tests and completed the Python 3.11 test environment.
- Removed high-risk Flutter async-context findings and kept lower-risk modernization debt visible.
- Added Java/Flutter GitHub Actions and recruiter-focused architecture/security documentation.

## Verified checks

- Java: 11 tests, 0 failures, 0 errors, 0 skipped.
- Python: 7 passed, 0 failed, 0 skipped; one dependency deprecation warning.
- Flutter: 1 test passed. Analyzer moved from 159 to 132 findings; no analyzer errors and no `use_build_context_synchronously` findings remain.

## Remaining debt

- Historical Gmail, PostgreSQL, and JWT credentials must be rotated; Git history was not rewritten.
- Add rate limiting for login, kiosk, and AI endpoints before exposing a public demo.
- Add PostgreSQL Testcontainers coverage and a versioned Flyway baseline for database parity/invariants.
- Define automated retention/deletion and encryption for stored eKYC images and embeddings.
- Owner decision is required before archiving/removing `SourceCode/Frontend`, `untitled4`, and the 2.2 MB manual face fixture.
- Remaining Flutter findings are warnings/style/deprecation cleanup, not analyzer errors or async-context hazards.

## Readiness

The repository is credible as a primary Backend Intern/Fresher portfolio project after the historical credentials are rotated. It demonstrates a real business invariant, transaction/locking reasoning, scoped kiosk authentication, API/AI failure handling, cross-language integration, and automated tests without claiming production scale or compliance.
