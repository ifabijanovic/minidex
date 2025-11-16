# AuthAPI

Lightweight authentication module for MiniDex built on Vapor + Fluent. It exposes registration, login, logout, and user-management APIs plus the authenticators/middleware shared by the rest of the server.

## Authentication Flow
- `UsernameAndPasswordAuthenticator` verifies credentials (Bcrypt) and loads a minimal `AuthUser` into `req.auth`.
- `AuthController.login` ensures the account is active + authorized, creates a random token, stores its SHA-256 hash in `DBUserToken`, and returns the Base64URL token string (plus expiry seconds).
- Clients call protected routes with `Authorization: Bearer <token>`. `TokenAuthenticator` first checks Redis (see below) and otherwise validates the hashed token against `DBUserToken`, rehydrates the joined `DBUser`, and caches the result.

## Redis Caching
- Cache entries live under two keys:
  - `token:<access-token>` → JSON-encoded `AuthUser` used by `TokenAuthenticator`.
  - `token_hash:<hashed-token>` → original access token string so revocation logic (which only knows the hashed value) can delete the corresponding `token:*` record.
- TTL always matches the DB token’s remaining lifetime (minimum 1s). Cache failures are best-effort: errors are logged but the request still falls back to main DB.
- Cache misses automatically repopulate Redis after a successful DB lookup so future authentications are single RTT Redis hits.

## Cache Invalidation
- `AuthController.logout` revokes the current token in main DB and invalidates both Redis keys via the hashed token lookup.
- `UserController.update` runs inside a DB transaction; if `roles` or `isActive` changes it clears every cached token for that user by iterating their `DBUserToken` rows and calling the same Redis invalidation helper.
- `UserController.revokeAccess` (admin-only) mass-revokes and invalidates all tokens for the specified user, ensuring cached data never bypasses server-side changes.

## Testing Notes
- `Tests/AuthAPITests` spin up an in-memory SQLite DB plus the `InMemoryRedisDriver` from `VaporRedisUtils`, asserting cache hits, misses, invalidations, and failure paths.
- `Application.makeTesting()` forces `logger.logLevel = .warning` so Redis and migration chatter stays quiet under `swift test`.
