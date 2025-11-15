import AuthDB
import Fluent
import FluentSQLiteDriver
import Vapor

enum TestDatabaseHelpers {
    static func migrate(_ app: Application) async throws {
        app.databases.use(.sqlite(.memory), as: .sqlite)
        app.migrations.add(AuthDB.migrations)
        try await app.autoMigrate()
    }

    static func reset(_ app: Application) async throws {
        try await app.autoRevert()
    }
}
