import AuthDB
import Fluent
import Redis
import Vapor
import VaporRedisUtils
import VaporUtils

public struct AuthOut: Content {
    public var accessToken: String
    public var expiresIn: Int
    public var userId: UUID
    public var roles: Set<String>
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
    let newUserRoles: Roles
    let rolesToStrings: @Sendable (Roles) -> Set<String>

    public init(
        tokenLength: Int,
        accessTokenExpiration: TimeInterval,
        newUserRoles: Roles,
        rolesToStrings: @escaping @Sendable (Roles) -> Set<String>,
    ) {
        self.tokenLength = tokenLength
        self.accessTokenExpiration = accessTokenExpiration
        self.newUserRoles = newUserRoles
        self.rolesToStrings = rolesToStrings
    }

    public func boot(routes: any RoutesBuilder) throws {
        let group = routes.grouped("v1", "auth")
        group.post("register", use: self.register)

        group
            .grouped(UsernameAndPasswordAuthenticator())
            .post("login", use: self.login)

        group
            .grouped(TokenAuthenticator())
            .grouped(AuthUser.guardMiddleware())
            .post("logout", use: self.logout)
    }

    @Sendable
    func login(req: Request) async throws -> AuthOut {
        var user = try req.auth.require(AuthUser.self)

        if !user.isActive {
            throw Abort(.forbidden, reason: "User is not active")
        }
        if user.roles.isEmpty {
            throw Abort(.forbidden, reason: "User not authorized to perform this action")
        }

        let token = generateToken(length: tokenLength)
        let userToken = try await createUserToken(
            userID: user.id,
            token: token,
            db: req.db,
        )
        user.tokenID = try userToken.requireID()

        await req.redisClient.cache(
            accessToken: token.rawEncoded,
            hashedAccessToken: token.hashedEncoded,
            user: user,
            accessTokenExpiration: accessTokenExpiration,
            logger: req.logger,
        )

        return .init(
            accessToken: token.rawEncoded,
            expiresIn: Int(accessTokenExpiration),
            userId: user.id,
            roles: rolesToStrings(user.roles),
        )
    }

    @Sendable
    func logout(req: Request) async throws -> HTTPStatus {
        let user = try req.auth.require(AuthUser.self)

        guard
            let tokenID = user.tokenID,
            let token = try await DBUserToken.find(tokenID, on: req.db)
        else {
            throw Abort(.notFound)
        }
        
        try await TokenRevocation.revoke(token, on: req.db, redis: req.redisClient, logger: req.logger)
        return .ok
    }

    @Sendable
    func register(req: Request) async throws -> Response {
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
            throw Abort(.conflict, reason: "Username already taken")
        }

        let token = generateToken(length: tokenLength)
        let (userID, userToken) = try await req.db.transaction { db in
            let user = DBUser(roles: newUserRoles.rawValue, isActive: true)
            try await user.save(on: db)
            let userID = try user.requireID()

            let credential = DBCredential(
                userID: userID,
                type: .usernameAndPassword,
                identifier: input.username,
                secret: try Bcrypt.hash(input.password)
            )
            try await credential.save(on: db)

            let userToken = try await createUserToken(
                userID: userID,
                token: token,
                db: db
            )
            return (userID, userToken)
        }

        req.logger.debug("Registered username: \(input.username) with ID: \(userID)")

        let user = try AuthUser(
            id: userID,
            roles: newUserRoles,
            isActive: true,
            tokenID: userToken.requireID(),
        )
        req.auth.login(user)

        await req.redisClient.cache(
            accessToken: token.rawEncoded,
            hashedAccessToken: token.hashedEncoded,
            user: user,
            accessTokenExpiration: userToken.expiresAt.timeIntervalSinceNow,
            logger: req.logger,
        )

        let response = Response(status: .created)
        let content = AuthOut(
            accessToken: token.rawEncoded,
            expiresIn: Int(userToken.expiresAt.timeIntervalSinceNow),
            userId: userID,
            roles: rolesToStrings(newUserRoles),
        )
        try response.content.encode(content)
        return response
    }

    private func createUserToken(
        userID: UUID,
        token: Token,
        db: any Database,
    ) async throws -> DBUserToken {
        let token = DBUserToken(
            userID: userID,
            type: .access,
            value: token.hashed,
            expiresAt: Date() + accessTokenExpiration
        )
        try await token.save(on: db)
        return token
    }

    struct Token {
        /// Base64 encoded raw access token that is returned to the API user
        let rawEncoded: String
        /// Hashed binary access token that is stored in DB
        let hashed: Data
        /// Base64 encoded hashed access token used for cache invalidation
        let hashedEncoded: String
    }

    private func generateToken(length: Int) -> Token {
        var bytes = [UInt8](repeating: 0, count: length)
        var rng = SystemRandomNumberGenerator()
        for i in 0..<length {
            bytes[i] = UInt8.random(in: 0...255, using: &rng)
        }
        let raw = Data(bytes)
        let hashed = Data(SHA256.hash(data: raw))

        return .init(
            rawEncoded: raw.base64URLEncodedString(),
            hashed: hashed,
            hashedEncoded: hashed.base64URLEncodedString(),
        )
    }
}
