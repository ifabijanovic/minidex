import AuthAPI
import AuthDB
import Fluent
import FluentSQLiteDriver
import Vapor
import VaporRedisUtils

enum AuthAPITestApp {
    static let defaultTokenLength = 32
    static let defaultExpiration: TimeInterval = 60 * 60

    static func withApp(
        tokenLength: Int = defaultTokenLength,
        accessTokenExpiration: TimeInterval = defaultExpiration,
        _ test: @Sendable (Application, InMemoryRedisDriver) async throws -> Void
    ) async throws {
        let app = try await Application.make(.testing)
        let redisDriver = InMemoryRedisDriver()

        do {
            try await TestDatabaseHelpers.migrate(app)

            app.useRedisClientOverride { request in
                redisDriver.makeClient(on: request.eventLoop)
            }

            try AuthController(
                tokenLength: tokenLength,
                accessTokenExpiration: accessTokenExpiration
            ).boot(routes: app.routes)
            try UserController().boot(routes: app.routes)

            try await test(app, redisDriver)
        } catch {
            try await TestDatabaseHelpers.reset(app)
            try await app.asyncShutdown()
            throw error
        }

        try await TestDatabaseHelpers.reset(app)
        try await app.asyncShutdown()
    }
}

