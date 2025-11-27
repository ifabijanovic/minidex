# AuthAPI

Lightweight authentication module for MiniDex built on Vapor + Fluent. Exposes registration, login, logout, and user-management APIs plus authenticators/middleware for the rest of the server.

## Authentication Flow
- user logs in via `/v1/auth/login` using Basic Authentication and gets back an access token
- all further API calls are made using that access token via Bearer authorization

## Redis Caching

### Design
Redis reduces authentication latency from ~5-10ms (database join) to ~1ms (Redis + PK lookup). The database is the authoritative source of truth for security state.

### Cache Keys
- `token:<access-token>` → JSON-encoded `AuthUser` (id, roles, isActive, tokenID)
- `token_hash:<hashed-token>` → original access token string (enables cache invalidation by hash)

### Cache Hit Flow
1. Check Redis for cached user
2. **Verify token not revoked/expired in database** (always, even on cache hit)
3. If valid, use cached user data

This ensures logout and revocation take effect immediately, even when Redis is unavailable.

### Cache Miss Flow
1. Query database: `DBUserToken` ⋈ `DBUser` filtered by token hash
2. Validate token (not revoked, not expired)
3. Cache result in Redis for future requests

### Cache Invalidation
- **Logout**: Revokes token in DB, best-effort invalidates Redis keys
- **Revoke Access**: Revokes all user tokens in DB, best-effort invalidates all cached tokens
- **Update User**: If roles/isActive change, **revokes all user tokens in DB** and invalidates cache

### Failure Handling
Redis failures are graceful:
- Read failures → fall back to database
- Write/invalidation failures → logged as ERROR, but system remains secure (DB revocation is sufficient)

### Security Guarantees
1. **Token revocation is immediate**: Logout, revokeAccess, and user role/status changes revoke tokens in the database within a transaction
2. **DB check on every request**: Even with cached user data, token revocation status is always verified against the database
3. **No stale permissions**: Changing user roles/status force re-authentication (all existing tokens are revoked)
4. **Idempotent updates**: Setting roles/status to their current values does not revoke tokens (avoids unnecessary session disruption)

### Known Limitations
1. **Performance benefit is modest**: ~4-9ms savings per request. Redis was primarily added as a learning exercise
2. **Role/status changes force re-login**: Users must re-authenticate after their roles or active status changes (this is intentional for security)

## Testing
`Tests/AuthAPITests` use in-memory SQLite + `InMemoryRedisDriver` to test cache hits, misses, invalidations, and failure scenarios.
