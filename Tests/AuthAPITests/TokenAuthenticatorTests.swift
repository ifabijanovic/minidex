@testable import AuthAPI
@testable import AuthDB
import Crypto
import Fluent
import Redis
import Vapor
import VaporRedisUtils
import VaporUtils
import Testing

@Suite("TokenAuthenticator", .serialized)
struct TokenAuthenticatorTests {
    private let authenticator = TokenAuthenticator()

    @Test("authenticates cached user with valid token")
    func cacheHitReturnsUser() async throws {
        try await withApp { app, redis in
            let dbUser = try await AuthAPITestHelpers.createUser(on: app.db, username: "eevee", roles: [.admin])
            let (encoded, raw) = makeTokenValue("cached-token")
            let token = try await storeToken(for: dbUser, rawToken: raw, expiresIn: 3600, isRevoked: false, on: app.db)

            let cached = AuthUser(id: try dbUser.requireID(), roles: [.admin], isActive: true, tokenID: try token.requireID())
            let client = redis.makeClient(on: app.eventLoopGroup.next())
            try await client.setex("token:\(encoded)", toJSON: cached, expirationInSeconds: 60)

            let req = makeRequest(app: app, bearerToken: encoded)
            try await authenticator.authenticate(bearer: .init(token: encoded), for: req)

            let authed = try req.auth.require(AuthUser.self)
            #expect(authed.id == cached.id)
        }
    }

    @Test("authenticates database token and caches result")
    func databaseTokenAuthenticatesAndCaches() async throws {
        try await withApp { app, redis in
            let dbUser = try await AuthAPITestHelpers.createUser(on: app.db, username: "misty", roles: [.admin])
            let (encoded, raw) = makeTokenValue("db-token")
            try await storeToken(for: dbUser, rawToken: raw, expiresIn: 3600, isRevoked: false, on: app.db)

            let req = makeRequest(app: app, bearerToken: encoded)
            try await authenticator.authenticate(bearer: .init(token: encoded), for: req)

            let expectedID = try dbUser.requireID()
            let authed = try req.auth.require(AuthUser.self)
            #expect(authed.id == expectedID)

            let snapshot = redis.snapshot()
            let userKey = RedisKey("token:\(encoded)")
            guard let hash = TokenAuthenticator.hashAccessToken(encoded) else {
                Issue.record("Failed to hash token")
                return
            }
            let hashedKey = RedisKey("token_hash:\(hash.base64URLEncodedString())")
            #expect(snapshot.entries[userKey] != nil)
            #expect(snapshot.entries[hashedKey] != nil)
        }
    }

    @Test("revoked token is rejected")
    func revokedTokenRejected() async throws {
        try await withApp { app, _ in
            let dbUser = try await AuthAPITestHelpers.createUser(on: app.db, username: "brock", roles: [.admin])
            let (encoded, raw) = makeTokenValue("revoked")
            try await storeToken(for: dbUser, rawToken: raw, expiresIn: 3600, isRevoked: true, on: app.db)

            let req = makeRequest(app: app, bearerToken: encoded)
            try await authenticator.authenticate(bearer: .init(token: encoded), for: req)
            #expect(req.auth.has(AuthUser.self) == false)
        }
    }

    @Test("expired token is rejected")
    func expiredTokenRejected() async throws {
        try await withApp { app, _ in
            let dbUser = try await AuthAPITestHelpers.createUser(on: app.db, username: "tracey", roles: [.admin])
            let (encoded, raw) = makeTokenValue("expired")
            try await storeToken(for: dbUser, rawToken: raw, expiresIn: -10, isRevoked: false, on: app.db)

            let req = makeRequest(app: app, bearerToken: encoded)
            try await authenticator.authenticate(bearer: .init(token: encoded), for: req)
            #expect(req.auth.has(AuthUser.self) == false)
        }
    }

    @Test("invalid bearer values are ignored")
    func invalidBearerIgnored() async throws {
        try await withApp { app, _ in
            let req = makeRequest(app: app, bearerToken: "not-base64@@@")
            try await authenticator.authenticate(bearer: .init(token: "not-base64@@@"), for: req)
            #expect(req.auth.has(AuthUser.self) == false)
        }
    }

    @Test("cache hit with revoked token is rejected")
    func cacheHitWithRevokedTokenRejected() async throws {
        try await withApp { app, redis in
            let dbUser = try await AuthAPITestHelpers.createUser(on: app.db, username: "dawn", roles: [.admin])
            let (encoded, raw) = makeTokenValue("cached-but-revoked")
            let token = try await storeToken(for: dbUser, rawToken: raw, expiresIn: 3600, isRevoked: false, on: app.db)

            let req1 = makeRequest(app: app, bearerToken: encoded)
            try await authenticator.authenticate(bearer: .init(token: encoded), for: req1)
            #expect(req1.auth.has(AuthUser.self) == true)

            let snapshot = redis.snapshot()
            let userKey = RedisKey("token:\(encoded)")
            #expect(snapshot.entries[userKey] != nil)

            token.isRevoked = true
            try await token.save(on: app.db)

            let req2 = makeRequest(app: app, bearerToken: encoded)
            try await authenticator.authenticate(bearer: .init(token: encoded), for: req2)
            #expect(req2.auth.has(AuthUser.self) == false)
        }
    }

    @Test("cache hit with expired token is rejected")
    func cacheHitWithExpiredTokenRejected() async throws {
        try await withApp { app, redis in
            let dbUser = try await AuthAPITestHelpers.createUser(on: app.db, username: "paul", roles: [.admin])
            let (encoded, raw) = makeTokenValue("cached-but-expired")
            let token = try await storeToken(for: dbUser, rawToken: raw, expiresIn: 3600, isRevoked: false, on: app.db)

            let req1 = makeRequest(app: app, bearerToken: encoded)
            try await authenticator.authenticate(bearer: .init(token: encoded), for: req1)
            #expect(req1.auth.has(AuthUser.self) == true)

            let snapshot = redis.snapshot()
            let userKey = RedisKey("token:\(encoded)")
            #expect(snapshot.entries[userKey] != nil)

            token.expiresAt = Date().addingTimeInterval(-10)
            try await token.save(on: app.db)

            let req2 = makeRequest(app: app, bearerToken: encoded)
            try await authenticator.authenticate(bearer: .init(token: encoded), for: req2)
            #expect(req2.auth.has(AuthUser.self) == false)
        }
    }

    @Test("cache hit with missing token is rejected")
    func cacheHitWithMissingTokenRejected() async throws {
        try await withApp { app, redis in
            let tokenID = UUID()
            let cached = AuthUser(id: UUID(), roles: [.admin], isActive: true, tokenID: tokenID)

            let accessToken = "cached-but-missing"
            let client = redis.makeClient(on: app.eventLoopGroup.next())
            try await client.setex("token:\(accessToken)", toJSON: cached, expirationInSeconds: 60)

            let req = makeRequest(app: app, bearerToken: accessToken)
            try await authenticator.authenticate(bearer: .init(token: accessToken), for: req)
            #expect(req.auth.has(AuthUser.self) == false)
        }
    }
}

// MARK: - Helpers

private func withApp(_ test: @escaping (Application, InMemoryRedisDriver) async throws -> Void) async throws {
    let app = try await Application.makeTesting()
    let redisDriver = InMemoryRedisDriver()
    try await TestDatabaseHelpers.migrate(app)
    app.useRedisClientOverride { request in
        redisDriver.makeClient(on: request.eventLoop)
    }

    do {
        try await test(app, redisDriver)
    } catch {
        app.clearRedisClientOverride()
        try await TestDatabaseHelpers.reset(app)
        try await app.asyncShutdown()
        throw error
    }

    app.clearRedisClientOverride()
    try await TestDatabaseHelpers.reset(app)
    try await app.asyncShutdown()
}

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
