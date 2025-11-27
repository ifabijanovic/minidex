#if canImport(Testing)
@testable import AuthAPI
import Redis
import Testing
import Vapor
import VaporUtils

extension InMemoryRedisDriver {
    public func assertAuthCacheSet(
        accessToken: String,
        userID: UUID,
        ttl: Int,
    ) throws {
        let tokenKey = TokenClient.userCacheKey(accessToken: accessToken)
        let cachedUser = try assertAdded(key: tokenKey, as: AuthUser.self, ttl: ttl)
        #expect(cachedUser.id == userID)

        let hashedAccessToken = try #require(TokenClient.hash(token: accessToken))
        let hashedKey = TokenClient.tokenCacheKey(
            hashedAccessToken: hashedAccessToken.base64URLEncodedString()
        )
        try assertAdded(key: hashedKey, as: String.self, ttl: ttl)
    }

    public func assertAuthCacheCleared(accessToken: String) throws {
        let userKey = TokenClient.userCacheKey(accessToken: accessToken)
        assertCleared(key: userKey)

        let hashedAccessToken = try #require(TokenClient.hash(token: accessToken))
        let hashedKey = TokenClient.tokenCacheKey(
            hashedAccessToken: hashedAccessToken.base64URLEncodedString()
        )
        assertCleared(key: hashedKey)
    }
}
#endif
