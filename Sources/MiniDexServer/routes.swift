import AuthAPI
import Fluent
import Vapor

func routes(_ app: Application, cacheChecksumSecret: String) throws {
    try app.register(collection: AuthController(
        tokenLength: Settings.Auth.tokenLength,
        accessTokenExpiration: Settings.Auth.accessTokenExpiration,
        cacheExpiration: Settings.Auth.cacheExpiration,
        checksumSecret: cacheChecksumSecret,
        newUserRoles: .hobbyist,
        rolesConverter: .minidex,
    ))

    // Admin routes
    try app.register(collection: UserController(
        cacheExpiration: Settings.Auth.cacheExpiration,
        checksumSecret: cacheChecksumSecret,
        rolesConverter: .minidex
    ))
    try app.register(collection: UserProfileAdminController())
    try app.register(collection: UserAdminController(rolesConverter: .minidex))

    try app.register(collection: MeController())
    try app.register(collection: GameSystemController())
    try app.register(collection: FactionController())
}
