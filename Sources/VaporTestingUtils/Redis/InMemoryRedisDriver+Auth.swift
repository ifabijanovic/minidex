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
        let cached = try assertAdded(key: tokenKey, as: CachedAuthUser.self, ttl: ttl)
        #expect(cached.user.id == userID)

        let hashedAccessToken = try #require(TokenClient.hash(token: accessToken))
        let lookupKey = TokenClient.tokenLookupKey(
            hashedAccessToken: hashedAccessToken.base64URLEncodedString()
        )
        try assertAdded(key: lookupKey, as: String.self, ttl: ttl)
    }

    public func assertAuthCacheCleared(accessToken: String) throws {
        let userKey = TokenClient.userCacheKey(accessToken: accessToken)
        assertCleared(key: userKey)

        let hashedAccessToken = try #require(TokenClient.hash(token: accessToken))
        let lookupKey = TokenClient.tokenLookupKey(
            hashedAccessToken: hashedAccessToken.base64URLEncodedString()
        )
        assertCleared(key: lookupKey)
    }
}
#endif
