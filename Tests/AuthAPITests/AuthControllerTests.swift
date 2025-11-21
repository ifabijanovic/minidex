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
            )
            let userID = try user.requireID()

            let login = try await AuthAPITestHelpers.login(app: app, username: "ash", password: "pikachu")
            #expect(login.userId == userID)

            let tokens = try await DBUserToken.query(on: app.db).all()
            #expect(tokens.count == 1)

            let snapshot = redis.snapshot()
            let userKey = RedisKey("token:\(login.accessToken)")
            guard let hash = TokenAuthenticator.hashAccessToken(login.accessToken) else {
                Issue.record("Failed to hash access token")
                return
            }
            let hashedKey = RedisKey("token_hash:\(hash.base64URLEncodedString())")

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
                "v1/auth/login",
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
                "v1/auth/login",
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
                "v1/auth/logout",
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

    @Test("logout returns not found when token missing")
    func logoutWithMissingTokenReturnsNotFound() async throws {
        try await AuthAPITestApp.withApp { app, redis in
            let user = try await AuthAPITestHelpers.createUser(
                on: app.db,
                username: "cilan",
                roles: [.admin],
                isActive: true
            )
            let login = try await AuthAPITestHelpers.login(app: app, username: "cilan", password: "Password!23")

            let token = try await DBUserToken.query(on: app.db)
                .filter(\.$user.$id == user.requireID())
                .first()
            try await token?.delete(on: app.db)

            try await app.testing().test(
                .POST,
                "v1/auth/logout",
                beforeRequest: { req in
                    AuthAPITestHelpers.authorize(&req, token: login.accessToken)
                },
                afterResponse: { res async in
                    #expect(res.status == .unauthorized)
                }
            )
        }
    }

    @Test("logout succeeds even if Redis invalidation fails")
    func logoutHandlesRedisInvalidationFailure() async throws {
        try await AuthAPITestApp.withApp { app, redis in
            let user = try await AuthAPITestHelpers.createUser(
                on: app.db,
                username: "iris",
                roles: [.admin],
                isActive: true
            )
            let userID = try user.requireID()
            let login = try await AuthAPITestHelpers.login(app: app, username: "iris", password: "Password!23")

            redis.failNextCommand("DEL")

            try await app.testing().test(
                .POST,
                "v1/auth/logout",
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
        }
    }

    @Test("registration rejects duplicate username")
    func registrationRejectsDuplicateUsername() async throws {
        try await AuthAPITestApp.withApp { app, _ in
            _ = try await AuthAPITestHelpers.createUser(
                on: app.db,
                username: "clemont",
                roles: [],
                isActive: false
            )

            try await app.testing().test(
                .POST,
                "v1/auth/register",
                beforeRequest: { req in
                    try req.content.encode([
                        "username": "clemont",
                        "password": "NewPassword!23",
                        "confirmPassword": "NewPassword!23"
                    ])
                },
                afterResponse: { res async in
                    #expect(res.status == .conflict)
                }
            )

            let credentials = try await DBCredential.query(on: app.db)
                .filter(\.$identifier == "clemont")
                .count()
            #expect(credentials == 1)
        }
    }

    @Test("registration succeeds for new username")
    func registrationSucceedsForNewUser() async throws {
        try await AuthAPITestApp.withApp { app, _ in
            try await app.testing().test(
                .POST,
                "v1/auth/register",
                beforeRequest: { req in
                    try req.content.encode([
                        "username": "bonnie",
                        "password": "Password!23",
                        "confirmPassword": "Password!23"
                    ])
                },
                afterResponse: { res async in
                    #expect(res.status == .created)
                }
            )

            let credential = try await DBCredential.query(on: app.db)
                .filter(\.$identifier == "bonnie")
                .first()

            let user = try await credential?.$user.get(on: app.db)
            #expect(user?.isActive == false)
            #expect(user?.roles == 0)
        }
    }
}
