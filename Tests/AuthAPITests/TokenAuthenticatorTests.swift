@testable import AuthAPI
@testable import AuthDB
import Crypto
import Fluent
import Redis
import Vapor
import VaporRedisUtils
import VaporUtils
import VaporTesting
import VaporTestingUtils
import Testing

@Suite("TokenAuthenticator", .serialized)
struct TokenAuthenticatorTests {
    private let authenticator = TokenAuthenticator(cacheExpiration: 30)

    @Test("authenticates cached user with valid token")
    func cacheHitReturnsUser() async throws {
        try await TestContext.run(migrations: AuthDB.migrations) { context in
            let app = context.app

            let dbUser = try await AuthenticatedTestContext.createUser(on: app.db, username: "ash", roles: .admin)
            let (encoded, raw) = makeTokenValue("cached-token")
            let token = try await storeToken(for: dbUser, rawToken: raw, expiresIn: 3600, isRevoked: false, on: app.db)

            let cached = AuthUser(id: try dbUser.requireID(), roles: [.admin], isActive: true, tokenID: try token.requireID())
            let client = context.redis.makeClient(on: app.eventLoopGroup.next())
            try await client.setex("token:\(encoded)", toJSON: cached, expirationInSeconds: 30)

            let req = makeRequest(app: app, bearerToken: encoded)
            try await authenticator.authenticate(bearer: .init(token: encoded), for: req)

            let authed = try req.auth.require(AuthUser.self)
            #expect(authed.id == cached.id)
        }
    }

    @Test("authenticates database token and caches result")
    func databaseTokenAuthenticatesAndCaches() async throws {
        try await TestContext.run(migrations: AuthDB.migrations) { context in
            let app = context.app

            let dbUser = try await AuthenticatedTestContext.createUser(on: app.db, username: "misty", roles: .admin)
            let (encoded, raw) = makeTokenValue("db-token")
            try await storeToken(for: dbUser, rawToken: raw, expiresIn: 3600, isRevoked: false, on: app.db)

            let req = makeRequest(app: app, bearerToken: encoded)
            try await authenticator.authenticate(bearer: .init(token: encoded), for: req)

            let expectedID = try dbUser.requireID()
            let authed = try req.auth.require(AuthUser.self)
            #expect(authed.id == expectedID)

            try context.redis.assertAuthCacheSet(accessToken: encoded, userID: expectedID, ttl: 30)
        }
    }

    @Test("revoked token is rejected")
    func revokedTokenRejected() async throws {
        try await TestContext.run(migrations: AuthDB.migrations) { context in
            let app = context.app

            let dbUser = try await AuthenticatedTestContext.createUser(on: app.db, username: "brock", roles: .admin)
            let (encoded, raw) = makeTokenValue("revoked")
            try await storeToken(for: dbUser, rawToken: raw, expiresIn: 3600, isRevoked: true, on: app.db)

            let req = makeRequest(app: app, bearerToken: encoded)
            try await authenticator.authenticate(bearer: .init(token: encoded), for: req)
            #expect(req.auth.has(AuthUser.self) == false)
        }
    }

    @Test("expired token is rejected")
    func expiredTokenRejected() async throws {
        try await TestContext.run(migrations: AuthDB.migrations) { context in
            let app = context.app

            let dbUser = try await AuthenticatedTestContext.createUser(on: app.db, username: "may", roles: .admin)
            let (encoded, raw) = makeTokenValue("expired")
            try await storeToken(for: dbUser, rawToken: raw, expiresIn: -10, isRevoked: false, on: app.db)

            let req = makeRequest(app: app, bearerToken: encoded)
            try await authenticator.authenticate(bearer: .init(token: encoded), for: req)
            #expect(req.auth.has(AuthUser.self) == false)
        }
    }

    @Test("invalid bearer values are ignored")
    func invalidBearerIgnored() async throws {
        try await TestContext.run(migrations: AuthDB.migrations) { context in
            let app = context.app

            let req = makeRequest(app: app, bearerToken: "not-base64@@@")
            try await authenticator.authenticate(bearer: .init(token: "not-base64@@@"), for: req)
            #expect(req.auth.has(AuthUser.self) == false)
        }
    }

    @Test("cache hit with revoked token is rejected")
    func cacheHitWithRevokedTokenRejected() async throws {
        try await TestContext.run(migrations: AuthDB.migrations) { context in
            let app = context.app

            let dbUser = try await AuthenticatedTestContext.createUser(on: app.db, username: "dawn", roles: .admin)
            let (encoded, raw) = makeTokenValue("cached-but-revoked")
            let token = try await storeToken(for: dbUser, rawToken: raw, expiresIn: 3600, isRevoked: false, on: app.db)

            let req1 = makeRequest(app: app, bearerToken: encoded)
            try await authenticator.authenticate(bearer: .init(token: encoded), for: req1)
            #expect(req1.auth.has(AuthUser.self) == true)

            try context.redis.assertAdded(key: "token:\(encoded)", as: AuthUser.self, ttl: 30)

            token.isRevoked = true
            try await token.save(on: app.db)

            let req2 = makeRequest(app: app, bearerToken: encoded)
            try await authenticator.authenticate(bearer: .init(token: encoded), for: req2)
            #expect(req2.auth.has(AuthUser.self) == false)
        }
    }

    @Test("cache hit with expired token is rejected")
    func cacheHitWithExpiredTokenRejected() async throws {
        try await TestContext.run(migrations: AuthDB.migrations) { context in
            let app = context.app

            let dbUser = try await AuthenticatedTestContext.createUser(on: app.db, username: "iris", roles: .admin)
            let (encoded, raw) = makeTokenValue("cached-but-expired")
            let token = try await storeToken(for: dbUser, rawToken: raw, expiresIn: 3600, isRevoked: false, on: app.db)

            let req1 = makeRequest(app: app, bearerToken: encoded)
            try await authenticator.authenticate(bearer: .init(token: encoded), for: req1)
            #expect(req1.auth.has(AuthUser.self) == true)

            try context.redis.assertAdded(key: "token:\(encoded)", as: AuthUser.self, ttl: 30)

            token.expiresAt = Date().addingTimeInterval(-10)
            try await token.save(on: app.db)

            let req2 = makeRequest(app: app, bearerToken: encoded)
            try await authenticator.authenticate(bearer: .init(token: encoded), for: req2)
            #expect(req2.auth.has(AuthUser.self) == false)
        }
    }

    @Test("cache hit with missing token is rejected")
    func cacheHitWithMissingTokenRejected() async throws {
        try await TestContext.run(migrations: AuthDB.migrations) { context in
            let app = context.app

            let tokenID = UUID()
            let cached = AuthUser(id: UUID(), roles: [.admin], isActive: true, tokenID: tokenID)

            let accessToken = "cached-but-missing"
            let client = context.redis.makeClient(on: app.eventLoopGroup.next())
            try await client.setex("token:\(accessToken)", toJSON: cached, expirationInSeconds: 60)

            let req = makeRequest(app: app, bearerToken: accessToken)
            try await authenticator.authenticate(bearer: .init(token: accessToken), for: req)
            #expect(req.auth.has(AuthUser.self) == false)
        }
    }
}

// MARK: - Helpers

private func makeRequest(app: Application, bearerToken: String) -> Request {
    let req = Request(application: app, on: app.eventLoopGroup.next())
    req.headers.bearerAuthorization = .init(token: bearerToken)
    return req
}

private func makeTokenValue(_ string: String) -> (encoded: String, raw: Data) {
    let raw = Data(string.utf8)
    return (raw.base64URLEncodedString(), raw)
}

@discardableResult
private func storeToken(
    for user: DBUser,
    rawToken: Data,
    expiresIn: TimeInterval,
    isRevoked: Bool,
    on db: any Database
) async throws -> DBUserToken {
    let token = DBUserToken(
        userID: try user.requireID(),
        type: .access,
        value: Data(SHA256.hash(data: rawToken)),
        expiresAt: Date().addingTimeInterval(expiresIn),
        isRevoked: isRevoked
    )
    try await token.save(on: db)
    return token
}
