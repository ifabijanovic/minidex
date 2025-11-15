import AuthDB
import Fluent
import Vapor

struct LoginOut: Content {
    var accessToken: String
    var expiresIn: Int
    var userId: UUID
    var displayName: String?
}

struct RegisterIn: Content, Validatable {
    var username: String
    var password: String
    var confirmPassword: String

    static func validations(_ validations: inout Validations) {
        validations.add("username", as: String.self, is: .count(3...))
        validations.add("password", as: String.self, is: .count(8...))
    }
}

public struct AuthController: RouteCollection, Sendable {
    let tokenLength: Int
    let accessTokenExpiration: TimeInterval

    public init(tokenLength: Int, accessTokenExpiration: TimeInterval) {
        self.tokenLength = tokenLength
        self.accessTokenExpiration = accessTokenExpiration
    }

    public func boot(routes: any RoutesBuilder) throws {
        let group = routes.grouped("api", "auth")
        group.post("register", use: self.register)
        group
            .grouped(UsernameAndPasswordAuthenticator())
            .post("login", use: self.login)
    }

    @Sendable
    func login(req: Request) async throws -> LoginOut {
        let user = try req.auth.require(User.self)

        if !user.isActive {
            throw Abort(.forbidden, reason: "User is not active")
        }
        if user.roles.isEmpty {
            throw Abort(.forbidden, reason: "User not authorized to perform this action")
        }

        let tokenValue = generateToken(length: tokenLength)
        let expiresAt = Date() + accessTokenExpiration

        let token = DBUserToken(
            userID: user.id,
            type: .access,
            value: Data(SHA256.hash(data: tokenValue)),
            expiresAt: expiresAt
        )
        try await token.save(on: req.db)

        return .init(
            accessToken: tokenValue.base64URLEncodedString(),
            expiresIn: Int(token.expiresAt.timeIntervalSinceNow),
            userId: user.id,
            displayName: user.displayName,
        )
    }

    @Sendable
    func register(req: Request) async throws -> HTTPStatus {
        try RegisterIn.validate(content: req)
        let input = try req.content.decode(RegisterIn.self)
        guard input.password == input.confirmPassword else {
            throw Abort(.badRequest, reason: "Passwords don't match")
        }

        if try await DBCredential
            .query(on: req.db)
            .filter(\.$type == .usernameAndPassword)
            .filter(\.$identifier == input.username)
            .first() != nil
        {
            req.logger.warning("Attempted to register with existing username '\(input.username)'")
            return .created
        }

        try await req.db.transaction { db in
            let user = DBUser()
            try await user.save(on: db)

            let credential = DBCredential(
                userID: try user.requireID(),
                type: .usernameAndPassword,
                identifier: input.username,
                secret: try Bcrypt.hash(input.password)
            )
            try await credential.save(on: db)
        }

        return .created
    }

    private func generateToken(length: Int) -> Data {
        var bytes = [UInt8](repeating: 0, count: length)
        var rng = SystemRandomNumberGenerator()
        for i in 0..<length {
            bytes[i] = UInt8.random(in: 0...255, using: &rng)
        }
        return Data(bytes)
    }
}
