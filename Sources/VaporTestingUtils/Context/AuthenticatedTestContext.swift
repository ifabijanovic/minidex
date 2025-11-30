#if canImport(Testing)
import AuthAPI
import AuthDB
import Fluent
import FluentSQLiteDriver
import Foundation
import Vapor
import VaporRedisUtils
import VaporTesting
import VaporUtils
import Testing

public struct AuthenticatedTestContext {
    public let app: Application
    public let redis: InMemoryRedisDriver
    public let token: String
    public let expiresIn: Int
    public let userID: UUID

    @discardableResult
    public static func run<T>(
        migrations: [any Migration] = [],
        tokenLength: Int = 32,
        accessTokenExpiration: TimeInterval = 60*60,
        cacheExpiration: TimeInterval = 30,
        username: String = "testUser",
        password: String = "Password!23",
        roles: Roles,
        isActive: Bool = true,
        rolesConverter: RolesConverter = .empty,
        _ body: @Sendable (AuthenticatedTestContext) async throws -> T,
    ) async throws -> T {
        let context = try await makeAuthenticatedContext(
            migrations: migrations,
            tokenLength: tokenLength,
            accessTokenExpiration: accessTokenExpiration,
            cacheExpiration: cacheExpiration,
            username: username,
            password: password,
            roles: roles,
            isActive: isActive,
            rolesConverter: rolesConverter,
        )
        do {
            let value = try await body(context)
            try await context.shutdown()
            return value
        } catch {
            try? await context.shutdown()
            throw error
        }
    }

    static func makeAuthenticatedContext(
        migrations: [any Migration],
        tokenLength: Int,
        accessTokenExpiration: TimeInterval,
        cacheExpiration: TimeInterval,
        username: String,
        password: String,
        roles: Roles,
        isActive: Bool,
        rolesConverter: RolesConverter,
    ) async throws -> AuthenticatedTestContext {
        let context = try await TestContext.makeContext(
            migrations: AuthDB.migrations + migrations,
        )

        let app = context.app
        let redisDriver = context.redis

        try app.register(collection: AuthController(
            tokenLength: tokenLength,
            accessTokenExpiration: accessTokenExpiration,
            cacheExpiration: cacheExpiration,
            checksumSecret: "test-secret",
            newUserRoles: roles,
            rolesConverter: rolesConverter,
        ))

        let user = try await createUser(
            on: app.db,
            username: username,
            password: password,
            roles: roles,
            isActive: isActive,
        )
        let userID = try user.requireID()

        let login = try await login(
            app: app,
            username: username,
            password: password,
        )
        #expect(login.userId == userID)

        return .init(
            app: app,
            redis: redisDriver,
            token: login.accessToken,
            expiresIn: login.expiresIn,
            userID: login.userId,
        )
    }

    func shutdown() async throws {
        app.clearRedisClientOverride()
        try await app.autoRevert()
        try await app.asyncShutdown()
    }

    @discardableResult
    public static func createUser(
        on db: any Database,
        username: String,
        password: String = "Password!23",
        roles: Roles,
        isActive: Bool = true,
    ) async throws -> DBUser {
        let user = DBUser(roles: roles.rawValue, isActive: isActive)
        try await user.save(on: db)

        let credential = DBCredential(
            userID: try user.requireID(),
            type: .usernameAndPassword,
            identifier: username,
            secret: try Bcrypt.hash(password)
        )
        try await credential.save(on: db)

        return user
    }

    public static func login(
        app: Application,
        username: String,
        password: String
    ) async throws -> AuthOut {
        var response: AuthOut?
        try await app.testing().test(
            .POST,
            "/v1/auth/login",
            beforeRequest: { req in
                req.headers.basicAuthorization = .init(username: username, password: password)
            },
            afterResponse: { res async throws in
                #expect(res.status == .ok)
                response = try res.content.decode(AuthOut.self)
            }
        )
        return try #require(response)
    }
}
#endif
