import AuthAPI
import Fluent
import Vapor

func routes(_ app: Application) throws {
    app.get { req async throws in
        try await req.view.render("index", ["title": "Hello Vapor!"])
    }

    app.get("hello") { req async -> String in
        "Hello, world!"
    }

    try app.register(collection: AuthController(
        tokenLength: Settings.Auth.tokenLength,
        accessTokenExpiration: Settings.Auth.accessTokenExpiration,
    ))
    try app.register(collection: MiniController())
    try app.register(collection: GameSystemController())
}
