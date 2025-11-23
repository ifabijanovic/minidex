import AuthAPI
import AuthDB
import Vapor
import VaporTestingUtils

enum AuthAPITestApp {
    static let defaultTokenLength = 32
    static let defaultExpiration: TimeInterval = 60 * 60

    static func withApp(
        newUserRoles: Roles = [],
        runTest: @Sendable (Application, InMemoryRedisDriver) async throws -> Void
    ) async throws {
        try await TestContext.run(migrations: AuthDB.migrations) { context in
            try context.app.register(
                collection: AuthController(
                    tokenLength: defaultTokenLength,
                    accessTokenExpiration: defaultExpiration,
                    newUserRoles: newUserRoles,
                )
            )
            try context.app.register(collection: UserController())
            try await runTest(context.app, context.redis)
        }
    }
}
