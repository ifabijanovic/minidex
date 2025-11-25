import AuthAPI
import AuthDB
import Vapor
import VaporTestingUtils

extension Roles {
    static let tester = Roles(rawValue: 1 << 1)
}

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
                    rolesConverter: .test,
                )
            )
            try context.app.register(collection: UserController(rolesConverter: .test))
            try await runTest(context.app, context.redis)
        }
    }
}

extension RolesConverter {
    static let test = RolesConverter(
        toStrings: { roles in
            var result = Set<String>()
            if roles.contains(.admin) { result.insert("admin") }
            if roles.contains(.tester) { result.insert("tester") }
            return result
        },
        toRoles: { strings in
            var result = Roles()
            if strings.contains("admin") { result.insert(.admin) }
            if strings.contains("tester") { result.insert(.tester) }
            return result
        }
    )
}
