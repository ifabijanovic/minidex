import AuthDB
import Fluent
import Vapor
import VaporRedisUtils

public struct TokenClient: Sendable {
    /// Checks if a token is valid (not revoked and not expired)
    public var isTokenValid: @Sendable (DBUserToken) -> Bool

    /// Hashes a token string into a storable form
    public var hashToken: @Sendable (String) -> Data?

    /// Revokes a token in the database and invalidates its cache entry
    public var revoke: @Sendable (DBUserToken, (any Database)?) async throws -> Void

    /// Revokes all non-revoked tokens for a user and invalidates their cache entries
    public var revokeAllActiveTokens: @Sendable (UUID, (any Database)?) async throws -> Void

    static func userCacheKey(accessToken: String) -> String {
        "token:\(accessToken)"
    }

    static func tokenCacheKey(hashedAccessToken: String) -> String {
        "token_hash:\(hashedAccessToken)"
    }
}

extension TokenClient {
    public func revoke(token: DBUserToken, db: (any Database)? = nil) async throws {
        try await revoke(token, db)
    }

    public func revokeAllActiveTokens(userID: UUID, db: (any Database)? = nil) async throws {
        try await revokeAllActiveTokens(userID, db)
    }
}
