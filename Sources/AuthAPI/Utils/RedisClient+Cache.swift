import Foundation
import Logging
import Redis

extension RedisClient {
    func getCachedUser(
        accessToken: String,
        logger: Logger,
    ) async -> AuthUser? {
        do {
            let key = TokenClient.userCacheKey(accessToken: accessToken)
            return try await get(RedisKey(key), asJSON: AuthUser.self)
        } catch {
            logger.error("User cache lookup in Redis failed: \(error)")
            return nil
        }
    }

    func cache(
        accessToken: String,
        hashedAccessToken: String,
        user: AuthUser,
        accessTokenExpiration: TimeInterval,
        logger: Logger,
    ) async {
        let ttl = Int(accessTokenExpiration)
        guard ttl > 0 else {
            logger.warning("Skipped caching token with TTL <= 0")
            return
        }

        do {
            // Cache user in Redis for fast lookup
            try await setex(
                RedisKey(TokenClient.userCacheKey(accessToken: accessToken)),
                toJSON: user,
                expirationInSeconds: ttl
            )
            // Cache raw token for cache invalidation
            try await setex(
                RedisKey(TokenClient.tokenCacheKey(hashedAccessToken: hashedAccessToken)),
                toJSON: accessToken,
                expirationInSeconds: ttl
            )

            if let tokenID = user.tokenID {
                logger.debug("Cached userID: \(user.id), tokenID: \(tokenID)")
            } else {
                logger.warning("Cached userID: \(user.id), tokenID missing!")
            }
        } catch {
            logger.error("Auth cache to Redis failed: \(error)")
        }
    }

    func invalidate(hashedAccessToken: String, logger: Logger) async {
        do {
            guard let accessToken = try await get(
                RedisKey(TokenClient.tokenCacheKey(hashedAccessToken: hashedAccessToken)),
                asJSON: String.self
            ) else {
                logger.debug("No auth cache to invalidate")
                return
            }
            _ = try await delete(RedisKey(TokenClient.userCacheKey(accessToken: accessToken))).get()
            _ = try await delete(RedisKey(TokenClient.tokenCacheKey(hashedAccessToken: hashedAccessToken))).get()
            logger.debug("Auth cache invalidated")
        } catch {
            logger.error("Auth cache invalidation from Redis failed: \(error)")
        }
    }
}
