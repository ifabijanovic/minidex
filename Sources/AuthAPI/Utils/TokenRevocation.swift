import AuthDB
import Fluent
import Logging
import Redis
import VaporRedisUtils

/// Handles token revocation with cache invalidation
enum TokenRevocation {
    /// Revokes a token in the database and invalidates its cache entry
    static func revoke(
        _ token: DBUserToken,
        on db: any Database,
        redis: any RedisClient,
        logger: Logger
    ) async throws {
        token.isRevoked = true
        try await token.save(on: db)
        
        await redis.invalidate(
            hashedAccessToken: token.value.base64URLEncodedString(),
            logger: logger
        )
    }
}

