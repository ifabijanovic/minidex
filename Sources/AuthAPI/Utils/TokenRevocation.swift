import AuthDB
import Fluent
import Foundation
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

        let tokenID = try token.requireID()
        logger.debug("Revoked tokenID: \(tokenID)")

        await redis.invalidate(
            hashedAccessToken: token.value.base64URLEncodedString(),
            logger: logger
        )
    }

    /// Revokes all non-revoked tokens for a user and invalidates their cache entries
    static func revokeAllActiveTokens(
        userID: UUID,
        db: any Database,
        redis: any RedisClient,
        logger: Logger,
    ) async throws {
        let allTokens = try await DBUserToken
            .query(on: db)
            .filter(\.$user.$id == userID)
            .all()

        for token in allTokens {
            let hashed = token.value.base64URLEncodedString()
            await redis.invalidate(hashedAccessToken: hashed, logger: logger)
        }

        try await DBUserToken
            .query(on: db)
            .filter(\.$user.$id == userID)
            .filter(\.$isRevoked == false)
            .set(\.$isRevoked, to: true)
            .update()
    }
}
