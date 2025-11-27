#if canImport(Testing)
import Fluent
import FluentSQLiteDriver
import Foundation
import Vapor
import VaporRedisUtils
import VaporTesting
import VaporUtils
import Testing

public struct TestContext {
    public let app: Application
    public let redis: InMemoryRedisDriver

    @discardableResult
    public static func run<T>(
        migrations: [any Migration] = [],
        _ body: @Sendable (TestContext) async throws -> T,
    ) async throws -> T {
        let context = try await makeContext(migrations: migrations)
        do {
            let value = try await body(context)
            try await context.shutdown()
            return value
        } catch {
            try? await context.shutdown()
            throw error
        }
    }

    static func makeContext(migrations: [any Migration]) async throws -> TestContext {
        let app = try await Application.make(.testing)
        app.logger.logLevel = .warning
        let redisDriver = InMemoryRedisDriver()
        app.useRedisClientOverride { request in
            redisDriver.makeClient(on: request.eventLoop)
        }
        app.databases.use(
            .sqlite(.memory, maxConnectionsPerEventLoop: 1),
            as: .sqlite
        )
        app.migrations.add(migrations)
        try await app.autoMigrate()

        return .init(
            app: app,
            redis: redisDriver,
        )
    }

    func shutdown() async throws {
        app.clearRedisClientOverride()
        try await app.autoRevert()
        try await app.asyncShutdown()
    }
}
#endif
