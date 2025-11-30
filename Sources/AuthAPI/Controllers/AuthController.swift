import AuthDB
import Fluent
import Redis
import SlackIntegration
import Vapor
import VaporRedisUtils
import VaporUtils

public struct AuthOut: Content {
    public var accessToken: String
    public var expiresIn: Int
    public var userId: UUID
    public var roles: Set<String>
}

public struct MeOut: Content {
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
    let cacheExpiration: TimeInterval
    let checksumSecret: String
    let newUserRoles: Roles
    let rolesConverter: RolesConverter

    public init(
        tokenLength: Int,
        accessTokenExpiration: TimeInterval,
        cacheExpiration: TimeInterval,
        checksumSecret: String,
        newUserRoles: Roles,
        rolesConverter: RolesConverter,
    ) {
        self.tokenLength = tokenLength
        self.accessTokenExpiration = accessTokenExpiration
        self.cacheExpiration = cacheExpiration
        self.checksumSecret = checksumSecret
        self.newUserRoles = newUserRoles
        self.rolesConverter = rolesConverter
    }

    public func boot(routes: any RoutesBuilder) throws {
        let group = routes.grouped("v1", "auth")
        group.post("register", use: self.register)

        group
            .grouped(UsernameAndPasswordAuthenticator())
            .post("login", use: self.login)

        let behindToken = group
            .grouped(TokenAuthenticator(cacheExpiration: cacheExpiration, checksumSecret: checksumSecret))
            .grouped(AuthUser.guardMiddleware())

        behindToken.get("me", use: self.me)
        behindToken.post("logout", use: self.logout)
    }

    func login(req: Request) async throws -> AuthOut {
        var user = try req.auth.require(AuthUser.self)

        if !user.isActive {
            throw Abort(.forbidden, reason: "User is not active")
        }
        if user.roles.isEmpty {
            throw Abort(.forbidden, reason: "User not authorized to perform this action")
        }

        let token = req.tokenClient.generateToken(tokenLength)
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
            cacheExpiration: cacheExpiration,
            checksumSecret: checksumSecret,
            logger: req.logger,
        )

        return .init(
            accessToken: token.rawEncoded,
            expiresIn: Int(accessTokenExpiration),
            userId: user.id,
            roles: rolesConverter.toStrings(user.roles),
        )
    }

    func logout(req: Request) async throws -> HTTPStatus {
        let user = try req.auth.require(AuthUser.self)

        guard
            let tokenID = user.tokenID,
            let token = try await DBUserToken.find(tokenID, on: req.db)
        else {
            throw Abort(.notFound)
        }
        
        try await req.tokenClient.revoke(token: token)
        return .ok
    }

    func me(req: Request) async throws -> MeOut {
        let user = try req.auth.require(AuthUser.self)
        return .init(
            userId: user.id,
            roles: rolesConverter.toStrings(user.roles),
        )
    }

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

        let token = req.tokenClient.generateToken(tokenLength)
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
            cacheExpiration: cacheExpiration,
            checksumSecret: checksumSecret,
            logger: req.logger,
        )

        let response = Response(status: .created)
        let content = AuthOut(
            accessToken: token.rawEncoded,
            expiresIn: Int(userToken.expiresAt.timeIntervalSinceNow),
            userId: userID,
            roles: rolesConverter.toStrings(newUserRoles),
        )
        try response.content.encode(content)

        if let slack = req.application.slack {
            Task.detached { [slack, logger = req.logger, userID] in
                do {
                    try await slack.send("New user registration - `\(userID)`", "#minidex-signups")
                } catch {
                    logger.error("Slack error: \(error)")
                }
            }
        }

        return response
    }

    private func createUserToken(
        userID: UUID,
        token: TokenClient.Token,
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
}
