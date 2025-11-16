import AuthDB
import Fluent
import Redis
import Vapor
import VaporRedisUtils
import VaporUtils

public struct TokenAuthenticator: AsyncBearerAuthenticator {
    public init() {}

    public func authenticate(bearer: BearerAuthorization, for request: Request) async throws {
        if let cached = await request.redisClient.getCachedUser(accessToken: bearer.token, logger: request.logger) {
            request.logger.debug("Token auth cache hit for userID: \(cached.id)")
            // Check token state even on cache hit
            if let tokenID = cached.tokenID,
               let token = try await DBUserToken.find(tokenID, on: request.db),
               isTokenValid(token)
            {
                request.auth.login(cached)
            }
            return
        }

        guard let hash = Self.hashAccessToken(bearer.token) else { return }

        let token = try await DBUserToken
            .query(on: request.db)
            .join(DBUser.self, on: \DBUserToken.$user.$id == \DBUser.$id)
            .filter(\.$value == hash)
            .first()

        if let token, isTokenValid(token) {
            let dbUser = try token.joined(DBUser.self)
            let user = try AuthUser(
                id: dbUser.requireID(),
                roles: .init(rawValue: dbUser.roles),
                isActive: dbUser.isActive,
                tokenID: token.requireID(),
            )
            request.auth.login(user)

            await request.redisClient.cache(
                accessToken: bearer.token,
                hashedAccessToken: hash.base64URLEncodedString(),
                user: user,
                accessTokenExpiration: token.expiresAt.timeIntervalSinceNow,
                logger: request.logger,
            )
        }
    }

    /// Checks if a token is valid (not revoked and not expired)
    private func isTokenValid(_ token: DBUserToken) -> Bool {
        !token.isRevoked && token.expiresAt.timeIntervalSinceNow > 0
    }

    /// Hashes an access token string into its database-storable form
    static func hashAccessToken(_ token: String) -> Data? {
        token
            .base64URLDecodedData()
            .map(SHA256.hash(data:))
            .map(Data.init(_:))
    }
}
