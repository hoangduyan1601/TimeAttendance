# Interview Notes

## System Architecture

```text
Flutter -> Spring Boot -> PostgreSQL
                   |
                   -> FastAPI -> face model
```

Flutter calls Spring Boot so authentication, authorization, attendance rules, and database transactions have one source of truth. FastAPI is stateless compute: it validates images and returns verification results; it never writes attendance.

## JWT Flow

Login -> BCrypt verification -> signed JWT -> Flutter token storage -> `Authorization: Bearer` -> JWT filter -> `SecurityContext` -> role authorization. The kiosk key is not a user JWT and grants only kiosk-route access.

## Attendance Concurrency

The current rule is one attendance record per employee per workday: first verified scan checks in and the next eligible scan checks out that record. `checkIn` and `verify` are transactional and load the user with a pessimistic write lock. Same-employee requests serialize, then re-check daily state. Duplicate check-in, checkout within 30 minutes, checkout after completion, or inconsistent state returns 409.

## AI Service Failure

The Java client uses a 3-second connection timeout and 10-second response timeout. Invalid/no-face results are rejected before an attendance write. AI unavailability or failure yields a generic response and no partial attendance commit. Blind retries are avoided because attendance commands must remain idempotent.

## Biometric Security

Embeddings are sensitive. Raw images and full vectors must not be logged or retained without need. This demo keeps uploads in memory, validates MIME/size/decode, and hides internal exceptions. Production still needs encryption, access auditing, consent, and retention/deletion policy; no compliance claim is made.

## H2 vs PostgreSQL

H2 provides fast isolated CI tests but does not perfectly reproduce PostgreSQL locking, arrays, indexes, or query planning. Service tests verify the lock contract; Testcontainers PostgreSQL remains the next parity step.

## Transaction Boundaries

Attendance needs a transaction because lock, state read, validation, and write form one atomic command. Approval flows need transactions when they update request state and related records. Read-only mapping and external AI inference alone do not justify broad transactions.

## Security Review Story

During a portfolio security review, I identified plaintext password storage, hard-coded credentials, overly broad public endpoints, and an attendance race condition. I migrated password handling to BCrypt, externalized configuration, restricted authorization, added kiosk authentication, serialized attendance writes, hardened AI uploads, and added regression tests. These were academic-project defects, not production incidents.

## Trade-offs

- Pessimistic locking is simple but reduces same-user concurrency.
- H2 keeps CI accessible; PostgreSQL Testcontainers improves parity at added Docker cost.
- `ddl-auto` is convenient locally; Flyway should follow a verified baseline schema.
- Rate limiting remains future work; Redis was not added for portfolio complexity.
- Historical snapshots and the 2.2 MB manual fixture await owner-approved cleanup.

## Questions to Practice

1. How is a JWT converted to Spring authorities?
2. Why is BCrypt used, and why is plaintext fallback unsafe?
3. What PostgreSQL behavior can H2 miss?
4. Where is the attendance transaction boundary?
5. How can concurrent check-ins race?
6. Why lock the employee row?
7. Which database constraint would further strengthen the invariant?
8. Why does Spring Boot call FastAPI rather than Flutter?
9. What happens when FastAPI is offline, slow, or malformed?
10. Why avoid blind attendance retries?
11. How is the kiosk credential scoped and rotated?
12. What biometric privacy risks remain?
13. Annotation validation versus business validation?
14. How are 400/401/403/404/409/500 distinguished?
15. Which trade-off would you revisit first in production?
