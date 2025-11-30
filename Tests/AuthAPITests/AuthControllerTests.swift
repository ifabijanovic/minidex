@testable import AuthAPI
@testable import AuthDB
import Fluent
import Testing
import Vapor
import VaporTesting
import VaporTestingUtils
import VaporRedisUtils
@preconcurrency import Redis

@Suite("AuthController", .serialized)
struct AuthControllerTests {
    static let cacheExpiration: TimeInterval = 30

    static func registerController(app: Application) throws {
        try app.register(collection: AuthController(
            tokenLength: 32,
            accessTokenExpiration: 60*60,
            cacheExpiration: cacheExpiration,
            checksumSecret: "test-secret",
            newUserRoles: .tester,
            rolesConverter: .test,
        ))
    }

    @Test("login issues token and caches user")
    func loginCachesUser() async throws {
        try await AuthenticatedTestContext.run(
            username: "ash",
            roles: .admin,
        ) { context in
            let app = context.app

            let tokens = try await DBUserToken.query(on: app.db).all()
            #expect(tokens.count == 1)

            try context.redis.assertAuthCacheSet(
                accessToken: context.token,
                userID: context.userID,
                ttl: Int(Self.cacheExpiration),
            )
        }
    }

    @Test("login rejects inactive user")
    func loginRejectsInactiveUser() async throws {
        try await TestContext.run(migrations: AuthDB.migrations) { context in
            let app = context.app
            try Self.registerController(app: app)

            try await AuthenticatedTestContext.createUser(
                on: app.db,
                username: "brock",
                roles: .admin,
                isActive: false,
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
            #expect(context.redis.snapshot().entries.isEmpty)
        }
    }

    @Test("login rejects user without roles")
    func loginRejectsRoleLessUser() async throws {
        try await TestContext.run(migrations: AuthDB.migrations) { context in
            let app = context.app
            try Self.registerController(app: app)

            try await AuthenticatedTestContext.createUser(
                on: app.db,
                username: "misty",
                roles: [],
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
            #expect(context.redis.snapshot().entries.isEmpty)
        }
    }

    @Test("login succeeds when Redis cache fails")
    func loginHandlesRedisFailure() async throws {
        try await TestContext.run(migrations: AuthDB.migrations) { context in
            let app = context.app
            try Self.registerController(app: app)

            try await AuthenticatedTestContext.createUser(
                on: app.db,
                username: "gary",
                roles: .admin,
            )

            context.redis.failNextCommand("SETEX")

            let login = try await AuthenticatedTestContext.login(app: app, username: "gary", password: "Password!23")
            #expect(!login.accessToken.isEmpty)

            let tokens = try await DBUserToken.query(on: app.db).count()
            #expect(tokens == 1)

            #expect(context.redis.snapshot().entries.isEmpty)
        }
    }

    @Test("logout revokes token and clears cache")
    func logoutRevokesToken() async throws {
        try await AuthenticatedTestContext.run(
            username: "serena",
            roles: .admin,
        ) { context in
            let app = context.app

            try await app.testing().test(
                .POST,
                "v1/auth/logout",
                beforeRequest: { req in
                    req.headers.bearerAuthorization = .init(token: context.token)
                },
                afterResponse: { res async in
                    #expect(res.status == .ok)
                }
            )

            let tokens = try await DBUserToken.query(on: app.db)
                .filter(\.$user.$id == context.userID)
                .all()
            #expect(tokens.count == 1)
            #expect(tokens.first?.isRevoked == true)

            try context.redis.assertAuthCacheCleared(accessToken: context.token)
        }
    }

    @Test("logout succeeds even if Redis invalidation fails")
    func logoutHandlesRedisInvalidationFailure() async throws {
        try await AuthenticatedTestContext.run(
            username: "iris",
            roles: .admin,
        ) { context in
            let app = context.app

            context.redis.failNextCommand("DEL")

            try await app.testing().test(
                .POST,
                "v1/auth/logout",
                beforeRequest: { req in
                    req.headers.bearerAuthorization = .init(token: context.token)
                },
                afterResponse: { res async in
                    #expect(res.status == .ok)
                }
            )

            let tokens = try await DBUserToken.query(on: app.db)
                .filter(\.$user.$id == context.userID)
                .all()
            #expect(tokens.count == 1)
            #expect(tokens.first?.isRevoked == true)

            #expect(context.redis.snapshot().entries.isEmpty == false)
        }
    }

    @Test("me returns active user roles")
    func meReturnsUserRoles() async throws {
        try await AuthenticatedTestContext.run(
            username: "dawn",
            roles: .tester,
            rolesConverter: .test,
        ) { context in
            let app = context.app

            try await app.testing().test(
                .GET,
                "v1/auth/me",
                beforeRequest: { req in
                    req.headers.bearerAuthorization = .init(token: context.token)
                },
                afterResponse: { res async throws in
                    #expect(res.status == .ok)
                    let dto = try res.content.decode(MeOut.self)
                    #expect(dto.userId == context.userID)
                    #expect(dto.roles == ["tester"])
                }
            )
        }
    }

    @Test("registration rejects duplicate username")
    func registrationRejectsDuplicateUsername() async throws {
        try await TestContext.run(migrations: AuthDB.migrations) { context in
            let app = context.app
            try Self.registerController(app: app)

            _ = try await AuthenticatedTestContext.createUser(
                on: app.db,
                username: "clemont",
                roles: .tester,
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
        try await TestContext.run(migrations: AuthDB.migrations) { context in
            let app = context.app
            try Self.registerController(app: app)

            var response: AuthOut?
            try await app.testing().test(
                .POST,
                "v1/auth/register",
                beforeRequest: { req in
                    try req.content.encode([
                        "username": "may",
                        "password": "Password!23",
                        "confirmPassword": "Password!23"
                    ])
                },
                afterResponse: { res async throws in
                    #expect(res.status == .created)
                    response = try res.content.decode(AuthOut.self)
                }
            )

            guard let response else {
                Issue.record("Register response missing")
                throw Abort(.internalServerError)
            }

            #expect(response.roles == ["tester"])

            let credential = try await DBCredential.query(on: app.db)
                .filter(\.$identifier == "may")
                .first()

            let user = try await credential?.$user.get(on: app.db)
            #expect(user?.isActive == true)
            #expect(user?.roles == Roles.tester.rawValue)

            let tokens = try await DBUserToken.query(on: app.db).all()
            #expect(tokens.count == 1)

            try context.redis.assertAuthCacheSet(
                accessToken: response.accessToken,
                userID: response.userId,
                ttl: Int(Self.cacheExpiration),
            )
        }
    }
}
