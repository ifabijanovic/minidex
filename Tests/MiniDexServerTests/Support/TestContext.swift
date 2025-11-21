@testable import MiniDexServer
import AuthAPI
import AuthDB
import Fluent
import FluentSQLiteDriver
import Foundation
import MiniDexDB
import Vapor
import VaporRedisUtils
import VaporTesting
import VaporUtils
import Testing

struct TestContext {
    let app: Application
    let token: String
    let userID: UUID

    @discardableResult
    static func withAuthenticatedContext<T>(
        username: String = "testUser",
        password: String = "Password!23",
        roles: Roles = .hobbyist,
        isActive: Bool = true,
        _ body: @Sendable (TestContext) async throws -> T
    ) async throws -> T {
        let context = try await makeAuthenticatedContext(
            username: username,
            password: password,
            roles: roles,
            isActive: isActive,
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
        username: String = "testUser",
        password: String = "Password!23",
        roles: Roles = .hobbyist,
        isActive: Bool = true,
    ) async throws -> TestContext {
        let app = try await Application.makeTesting()
        let redisDriver = InMemoryRedisDriver()
        app.useRedisClientOverride { request in
            redisDriver.makeClient(on: request.eventLoop)
        }
        app.databases.use(.sqlite(.memory), as: .sqlite)
        app.migrations.add(AuthDB.migrations)
        app.migrations.add(MiniDexDB.migrations)
        try await app.autoMigrate()
        try routes(app)

        let user = DBUser(roles: roles.rawValue, isActive: isActive)
        try await user.save(on: app.db)
        let userID = try user.requireID()
        let username = username
        let password = password
        let credential = DBCredential(
            userID: userID,
            type: .usernameAndPassword,
            identifier: username,
            secret: try Bcrypt.hash(password)
        )
        try await credential.save(on: app.db)

        let login = try await loginUser(
            app: app,
            username: username,
            password: password
        )
        #expect(login.userId == userID)

        return .init(
            app: app,
            token: login.accessToken,
            userID: login.userId
        )
    }

    func shutdown() async throws {
        app.clearRedisClientOverride()
        try await app.autoRevert()
        try await app.asyncShutdown()
    }
}

private struct LoginResponse: Content {
    let accessToken: String
    let userId: UUID
}

private func loginUser(app: Application, username: String, password: String) async throws -> LoginResponse {
    var response: LoginResponse?
    try await app.testing().test(.POST, "/v1/auth/login", beforeRequest: { req in
        req.headers.basicAuthorization = .init(username: username, password: password)
    }, afterResponse: { res async throws in
        #expect(res.status == .ok)
        response = try res.content.decode(LoginResponse.self)
    })
    guard let login = response else {
        Issue.record("Missing login response")
        throw Abort(.internalServerError)
    }
    return login
}
