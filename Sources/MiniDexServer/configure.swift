import AuthDB
import Fluent
import FluentPostgresDriver
import Leaf
import MiniDexDB
import NIOSSL
import Vapor

// configures your application
public func configure(_ app: Application) async throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    guard let hostname = Settings.DB.hostname else { throw InvalidDBSettingsError(key: "DATABASE_HOST") }
    guard let username = Settings.DB.username else { throw InvalidDBSettingsError(key: "DATABASE_USERNAME") }
    guard let password = Settings.DB.password else { throw InvalidDBSettingsError(key: "DATABASE_PASSWORD") }
    guard let database = Settings.DB.database else { throw InvalidDBSettingsError(key: "DATABASE_NAME") }

    app.databases.use(
        DatabaseConfigurationFactory.postgres(
            configuration: .init(
                hostname: hostname,
                port: Settings.DB.port ?? SQLPostgresConfiguration.ianaPortNumber,
                username: username,
                password: password,
                database: database,
                tls: .prefer(
                    try .init(configuration: .clientDefault)
                )
            )
        ),
        as: .psql
    )

    app.migrations.add(AuthDB.migrations)
    app.migrations.add(Migration_CreateAdminUser(logger: app.logger))
    app.migrations.add(MiniDexDB.migrations)

    app.views.use(.leaf)

    // register routes
    try routes(app)
}
