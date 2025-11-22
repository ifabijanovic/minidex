import AuthDB
import Fluent
import Logging
import Redis
import Vapor
import VaporRedisUtils
import VaporUtils

public struct UserController: RestCrudController {
    public typealias DBModel = DBUser

    public struct DTO: Content {
        public var id: UUID
        public var roles: Roles
        public var isActive: Bool
    }

    public struct PostDTO: Content {
        public var roles: Roles
        public var isActive: Bool
    }

    public struct PatchDTO: Content {
        public var roles: Roles?
        public var isActive: Bool?
    }

    public init() {}

    public func toDTO(_ dbModel: DBUser) throws -> DTO {
        try .init(
            id: dbModel.requireID(),
            roles: .init(rawValue: dbModel.roles),
            isActive: dbModel.isActive,
        )
    }

    public func boot(routes: any RoutesBuilder) throws {
        let root = routes
            .grouped("v1", "users")
            .grouped(TokenAuthenticator())
            .grouped(AuthUser.guardMiddleware())
            .grouped(RequireAdminMiddleware())

        root.get(use: self.index)
        root.post(use: self.create { dto, _ in
            .init(roles: dto.roles.rawValue, isActive: dto.isActive)
        })
        root.group(":id") { route in
            route.get(use: self.get)
            route.patch(use: self.update)
            route.post("revokeAccess", use: self.revokeAccess)
        }
    }

    func update(req: Request) async throws -> DTO {
        let userID = try req.parameters.require("id", as: UUID.self)
        guard let dbModel = try await DBUser.find(userID, on: req.db) else {
            throw Abort(.notFound)
        }
        let patch = try req.content.decode(PatchDTO.self)

        var userAccessChanged = false
        if let value = patch.roles {
            userAccessChanged = dbModel.roles != value.rawValue
            dbModel.roles = value.rawValue
        }
        if let value = patch.isActive {
            userAccessChanged = userAccessChanged || (dbModel.isActive != value)
            dbModel.isActive = value
        }

        let updated = try toDTO(dbModel)

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
