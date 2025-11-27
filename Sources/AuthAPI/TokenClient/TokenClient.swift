import AuthDB
import Fluent
import Vapor
import VaporRedisUtils

public struct TokenClient: Sendable {
    public struct Token: Sendable {
        /// Base64 encoded raw access token that is returned to the API user
        public let rawEncoded: String
        /// Hashed binary access token that is stored in DB
        public let hashed: Data
        /// Base64 encoded hashed access token used for cache invalidation
        public let hashedEncoded: String
    }

    /// Generate a new random token
    public var generateToken: @Sendable (Int) -> Token

    /// Checks if a token is valid (not revoked and not expired)
    public var isTokenValid: @Sendable (DBUserToken) -> Bool

    /// Hashes a token string into a storable form
    public var hashToken: @Sendable (String) -> Data?

    /// Revokes a token in the database and invalidates its cache entry
    public var revoke: @Sendable (DBUserToken, (any Database)?) async throws -> Void

    /// Revokes all non-revoked tokens for a user and invalidates their cache entries
    public var revokeAllActiveTokens: @Sendable (UUID, (any Database)?) async throws -> Void
}

extension TokenClient {
    public func revoke(token: DBUserToken, db: (any Database)? = nil) async throws {
        try await revoke(token, db)
    }

    public func revokeAllActiveTokens(userID: UUID, db: (any Database)? = nil) async throws {
        try await revokeAllActiveTokens(userID, db)
    }
}
