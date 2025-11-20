import AuthDB
import Fluent
import Logging
import Redis
import Vapor
import VaporRedisUtils
import VaporUtils

struct UserPatchIn: Content {
    public var displayName: String?
    public var roles: Roles?
    public var isActive: Bool?
}

public struct UserController: RouteCollection, Sendable {
    public init() {}

    let crud: ApiCrudController<DBUser, User, UserPatchIn> = .init(
        toDTO: { try .init(db: $0) },
        toModel: {
            .init(
                id: $0.id,
                displayName: $0.displayName,
                roles: $0.roles.rawValue,
                isActive: $0.isActive
            )
        }
    )

    public func boot(routes: any RoutesBuilder) throws {
        let root = routes
            .grouped("v1", "user")
            .grouped(TokenAuthenticator())
            .grouped(AuthUser.guardMiddleware())
            .grouped(RequireAdminMiddleware())

        root.get(use: crud.index)
        root.post(use: crud.create)
        root.group(":id") { route in
            route.get(use: crud.get)
            route.patch(use: self.update)
            route.post("revokeAccess", use: self.revokeAccess)
        }
    }

    @Sendable
    func update(req: Request) async throws -> User {
        let userID = try req.parameters.require("id", as: UUID.self)
        guard let dbModel = try await DBUser.find(userID, on: req.db) else {
            throw Abort(.notFound)
        }
        let patch = try req.content.decode(UserPatchIn.self)

        var userAccessChanged = false
        if let value = patch.displayName { dbModel.displayName = value }
        if let value = patch.roles {
            userAccessChanged = dbModel.roles != value.rawValue
            dbModel.roles = value.rawValue
        }
        if let value = patch.isActive {
            userAccessChanged = userAccessChanged || (dbModel.isActive != value)
            dbModel.isActive = value
        }

        let updated = try User(db: dbModel)

        if userAccessChanged {
            req.logger.debug("User access changed, revoking tokens...")
            try await req.db.transaction { db in
                try await dbModel.save(on: db)
                try await TokenRevocation.revokeAllActiveTokens(
                    userID: userID,
                    db: db,
                    redis: req.redisClient,
                    logger: req.logger
                )
            }
            req.logger.debug("Revoked tokens for userID: \(userID)")
        } else {
            try await dbModel.save(on: req.db)
        }

        return updated
    }

    @Sendable
    func revokeAccess(req: Request) async throws -> HTTPStatus {
        let userID = try req.parameters.require("id", as: UUID.self)
        try await TokenRevocation.revokeAllActiveTokens(
            userID: userID,
            db: req.db,
            redis: req.redisClient,
            logger: req.logger
        )
        req.logger.debug("Revoked access for userID: \(userID)")
        return .ok
    }
}

extension User {
    init(db: DBUser) throws {
        self.id = try db.requireID()
        self.displayName = db.displayName
        self.roles = .init(rawValue: db.roles)
        self.isActive = db.isActive
    }
}
