# Legacy Password Migration

The application authenticates only BCrypt hashes. It deliberately does not compare a submitted password with legacy plaintext data.

Before deploying against an older database:

1. Back up the database using the normal PostgreSQL backup process.
2. Identify password values that do not begin with a supported BCrypt prefix (`$2a$`, `$2b$`, or `$2y$`). Do not export or log those values.
3. Invalidate those accounts and issue password-reset links or administrator-generated temporary passwords through an approved channel.
4. Store only the BCrypt output produced by the application, then verify the old plaintext value is no longer present in backups retained for normal operations.

The login service returns a password-reset-required error for a legacy value. No data migration is claimed here because this repository has no access to a production database.
