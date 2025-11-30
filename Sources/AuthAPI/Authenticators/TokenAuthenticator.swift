import AuthDB
import Fluent
import Redis
import Vapor
import VaporRedisUtils
import VaporUtils

public struct TokenAuthenticator: AsyncBearerAuthenticator {
    let cacheExpiration: TimeInterval
    let checksumSecret: String

    public init(cacheExpiration: TimeInterval, checksumSecret: String) {
        self.cacheExpiration = cacheExpiration
        self.checksumSecret = checksumSecret
    }

    public func authenticate(bearer: BearerAuthorization, for request: Request) async throws {
        if let cached = await request.redisClient.getCachedUser(
            accessToken: bearer.token,
            checksumSecret: checksumSecret,
            logger: request.logger
        ) {
            // Tokens are short-lived in cache so we trust them without additional checks
            request.logger.debug("Token auth cache hit for userID: \(cached.id)")
            request.auth.login(cached)
            return
        }

        request.logger.debug("Token auth cache miss")
        guard let hash = request.tokenClient.hashToken(bearer.token) else { return }

        let token = try await DBUserToken
            .query(on: request.db)
            .join(DBUser.self, on: \DBUserToken.$user.$id == \DBUser.$id)
            .filter(\.$value == hash)
            .first()

        if let token, request.tokenClient.isTokenValid(token) {
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
                cacheExpiration: cacheExpiration,
                checksumSecret: checksumSecret,
                logger: request.logger,
            )
            request.logger.debug("Auth token verified for userID: \(user.id)")
        } else {
            request.logger.debug("Token auth failed")
        }
    }
}
