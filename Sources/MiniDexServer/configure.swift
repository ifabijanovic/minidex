import AuthDB
import Fluent
import FluentPostgresDriver
import MiniDexDB
import NIOSSL
import Redis
import SlackIntegration
import Vapor

// configures your application
public func configure(_ app: Application) async throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    guard let dbHostname = Settings.DB.hostname else { throw InvalidDBSettingsError(key: "DATABASE_HOST") }
    guard let dbPort = Settings.DB.port else { throw InvalidDBSettingsError(key: "DATABASE_PORT") }
    guard let dbUsername = Settings.DB.username else { throw InvalidDBSettingsError(key: "DATABASE_USERNAME") }
    guard let dbPassword = Settings.DB.password else { throw InvalidDBSettingsError(key: "DATABASE_PASSWORD") }
    guard let dbName = Settings.DB.database else { throw InvalidDBSettingsError(key: "DATABASE_NAME") }
    guard let redisHostname = Settings.Redis.hostname else { throw InvalidDBSettingsError(key: "REDIS_HOST") }
    guard let redisPort = Settings.Redis.port else { throw InvalidDBSettingsError(key: "REDIS_PORT") }
    guard let cacheChecksumSecret = Settings.Auth.cacheChecksumSecret else {
        throw InvalidDBSettingsError(key: "AUTH_CACHE_CHECKSUM_SECRET")
    }

    app.databases.use(
        DatabaseConfigurationFactory.postgres(
            configuration: .init(
                hostname: dbHostname,
                port: dbPort,
                username: dbUsername,
                password: dbPassword,
                database: dbName,
                tls: .prefer(
                    try .init(configuration: .clientDefault)
                )
            )
        ),
        as: .psql
    )

    app.redis.configuration = try RedisConfiguration(
        hostname: redisHostname,
        port: redisPort,
    )

    if let token = Settings.Slack.botToken {
        app.slack = .vapor(client: app.client, token: token)
        app.logger.debug("Slack integration is enabled")
    }

    app.migrations.add(AuthDB.migrations)
    app.migrations.add(Migration_CreateAdminUser(logger: app.logger))
    app.migrations.add(MiniDexDB.migrations)

    // register routes
    try routes(app, cacheChecksumSecret: cacheChecksumSecret)
}
