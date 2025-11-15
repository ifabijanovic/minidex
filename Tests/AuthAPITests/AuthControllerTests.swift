@testable import AuthAPI
@testable import AuthDB
import Fluent
import Testing
import Vapor
import VaporTesting
import VaporRedisUtils
@preconcurrency import Redis

@Suite("AuthController", .serialized)
struct AuthControllerTests {
    @Test("login issues token and caches user")
    func loginCachesUser() async throws {
        try await AuthAPITestApp.withApp { app, redis in
            let user = try await AuthAPITestHelpers.createUser(
                on: app.db,
                username: "ash",
                password: "pikachu",
                roles: [.admin],
                displayName: "Ash"
            )
            let userID = try user.requireID()

            let login = try await AuthAPITestHelpers.login(app: app, username: "ash", password: "pikachu")
            #expect(login.userId == userID)

            let tokens = try await DBUserToken.query(on: app.db).all()
            #expect(tokens.count == 1)

            let snapshot = redis.snapshot()
            let userKey = RedisKey("token:\(login.accessToken)")
            let hashedKey = RedisKey("token_hash:\(try AuthAPITestHelpers.hashAccessToken(login.accessToken))")

            let cachedUserData = try #require(snapshot.entries[userKey]?.data)
            let cachedUser = try JSONDecoder().decode(AuthUser.self, from: cachedUserData)
            #expect(cachedUser.id == user.id)

            #expect(snapshot.entries[hashedKey]?.data != nil)

            let ttl = snapshot.setexCalls.filter { $0.key == userKey }.first?.ttl
            #expect(ttl == Int(AuthAPITestApp.defaultExpiration))
        }
    }

    @Test("login rejects inactive user")
    func loginRejectsInactiveUser() async throws {
        try await AuthAPITestApp.withApp { app, redis in
            _ = try await AuthAPITestHelpers.createUser(
                on: app.db,
                username: "brock",
                roles: [.admin],
                isActive: false
            )

            try await app.testing().test(
                .POST,
                "api/auth/login",
                beforeRequest: { req in
                    req.headers.basicAuthorization = .init(username: "brock", password: "Password!23")
                },
                afterResponse: { res async in
                    #expect(res.status == .forbidden)
                }
            )

            let tokens = try await DBUserToken.query(on: app.db).count()
            #expect(tokens == 0)
            #expect(redis.snapshot().entries.isEmpty)
        }
    }

    @Test("login rejects user without roles")
    func loginRejectsRoleLessUser() async throws {
        try await AuthAPITestApp.withApp { app, redis in
            _ = try await AuthAPITestHelpers.createUser(
                on: app.db,
                username: "misty",
                roles: [],
                isActive: true
            )

            try await app.testing().test(
                .POST,
                "api/auth/login",
                beforeRequest: { req in
                    req.headers.basicAuthorization = .init(username: "misty", password: "Password!23")
                },
                afterResponse: { res async in
                    #expect(res.status == .forbidden)
                }
            )

            let tokens = try await DBUserToken.query(on: app.db).count()
            #expect(tokens == 0)
            #expect(redis.snapshot().entries.isEmpty)
        }
    }

    @Test("login succeeds when Redis cache fails")
    func loginHandlesRedisFailure() async throws {
        try await AuthAPITestApp.withApp { app, redis in
            _ = try await AuthAPITestHelpers.createUser(
                on: app.db,
                username: "gary",
                roles: [.admin],
                isActive: true
            )

            redis.failNextCommand("SETEX")

            let login = try await AuthAPITestHelpers.login(app: app, username: "gary", password: "Password!23")
            #expect(!login.accessToken.isEmpty)

            let tokens = try await DBUserToken.query(on: app.db).count()
            #expect(tokens == 1)
        }
    }

    @Test("logout revokes token and clears cache")
    func logoutRevokesToken() async throws {
        try await AuthAPITestApp.withApp { app, redis in
            let user = try await AuthAPITestHelpers.createUser(
                on: app.db,
                username: "serena",
                roles: [.admin],
                isActive: true
            )
            let userID = try user.requireID()
            let login = try await AuthAPITestHelpers.login(app: app, username: "serena", password: "Password!23")

            try await app.testing().test(
                .POST,
                "api/auth/logout",
                beforeRequest: { req in
                    AuthAPITestHelpers.authorize(&req, token: login.accessToken)
                },
                afterResponse: { res async in
                    #expect(res.status == .ok)
                }
            )

            let tokens = try await DBUserToken.query(on: app.db)
                .filter(\.$user.$id == userID)
                .all()
            #expect(tokens.count == 1)
            #expect(tokens.first?.isRevoked == true)

            try AuthAPITestHelpers.assertCacheCleared(for: login, redis: redis)
        }
    }
}
