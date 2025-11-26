#if canImport(Testing)
@testable import AuthAPI
import Testing
import Vapor
import VaporUtils

extension InMemoryRedisDriver {
    public func assertAuthCacheCleared(accessToken: String, client: TokenClient) throws {
        let userKey = TokenClient.userCacheKey(accessToken: accessToken)
        assertCleared(key: userKey)

        guard let hashedAccessToken = client.hashToken(accessToken) else {
            throw Abort(.internalServerError, reason: "Failed to decode access token")
        }
        let hashedKey = TokenClient.tokenCacheKey(
            hashedAccessToken: hashedAccessToken.base64URLEncodedString()
        )
        assertCleared(key: hashedKey)
    }
}
#endif
