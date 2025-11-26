import AuthDB
import Fluent
import Redis
import Vapor
import VaporRedisUtils

/// Handles token revocation with cache invalidation
public struct TokenClient: Sendable {
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

extension TokenClient {
    static func vapor(req: Request) -> TokenClient {
        .init(
            revoke: { token, db in
                token.isRevoked = true
                try await token.save(on: db ?? req.db)

                let tokenID = try token.requireID()
                req.logger.debug("Revoked tokenID: \(tokenID)")

                await req.redisClient.invalidate(
                    hashedAccessToken: token.value.base64URLEncodedString(),
                    logger: req.logger
                )
            },
            revokeAllActiveTokens: { userID, db in
                let allTokens = try await DBUserToken
                    .query(on: db ?? req.db)
                    .filter(\.$user.$id == userID)
                    .all()

                for token in allTokens {
                    let hashed = token.value.base64URLEncodedString()
                    await req.redisClient.invalidate(
                        hashedAccessToken: hashed,
                        logger: req.logger
                    )
                }

                try await DBUserToken
                    .query(on: db ?? req.db)
                    .filter(\.$user.$id == userID)
                    .filter(\.$isRevoked == false)
                    .set(\.$isRevoked, to: true)
                    .update()

                req.logger.debug("Revoked all active tokens for userID: \(userID)")
            }
        )
    }
}

extension Request {
    struct TokenClientKey: StorageKey {
        typealias Value = TokenClient
    }

    public var tokenClient: TokenClient {
        if let client = storage[TokenClientKey.self] {
            return client
        }
        let client = TokenClient.vapor(req: self)
        storage[TokenClientKey.self] = client
        return client
    }
}
