import AuthAPI
import Fluent
import Vapor

func routes(_ app: Application) throws {
    try app.register(collection: AuthController(
        tokenLength: Settings.Auth.tokenLength,
        accessTokenExpiration: Settings.Auth.accessTokenExpiration,
    ))
    try app.register(collection: UserController())
    try app.register(collection: UserProfileController())
    try app.register(collection: MiniController())
    try app.register(collection: GameSystemController())
}
