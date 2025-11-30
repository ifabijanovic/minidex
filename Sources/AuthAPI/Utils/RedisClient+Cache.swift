import Foundation
import Logging
import Redis

extension RedisClient {
    func getCachedUser(
        accessToken: String,
        checksumSecret: String,
        logger: Logger,
    ) async -> AuthUser? {
        do {
            let key = TokenClient.userCacheKey(accessToken: accessToken)
            guard let cached = try await get(RedisKey(key), asJSON: CachedAuthUser.self) else {
                return nil
            }

            guard cached.isValid(secret: checksumSecret) else {
                logger.warning("Cached user data failed checksum validation for userID: \(cached.user.id)")
                _ = try? await delete(RedisKey(key)).get()
                return nil
            }
            
            return cached.user
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
        cacheExpiration: TimeInterval,
        checksumSecret: String,
        logger: Logger,
    ) async {
        let ttl = Int(min(cacheExpiration, accessTokenExpiration))
        guard ttl > 0 else {
            logger.warning("Skipped caching token with TTL <= 0")
            return
        }

        do {
            let cached = CachedAuthUser(user: user, checksumSecret: checksumSecret)
            
            // Cache user in Redis for fast lookup
            try await setex(
                RedisKey(TokenClient.userCacheKey(accessToken: accessToken)),
                toJSON: cached,
                expirationInSeconds: ttl
            )
            // Cache raw token for cache invalidation
            try await setex(
                RedisKey(TokenClient.tokenLookupKey(hashedAccessToken: hashedAccessToken)),
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
                RedisKey(TokenClient.tokenLookupKey(hashedAccessToken: hashedAccessToken)),
                asJSON: String.self
            ) else {
                logger.debug("No auth cache to invalidate")
                return
            }
            _ = try await delete(RedisKey(TokenClient.userCacheKey(accessToken: accessToken))).get()
            _ = try await delete(RedisKey(TokenClient.tokenLookupKey(hashedAccessToken: hashedAccessToken))).get()
            logger.debug("Auth cache invalidated")
        } catch {
            logger.error("Auth cache invalidation from Redis failed: \(error)")
        }
    }
}
