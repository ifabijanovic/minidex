import AuthDB
import Fluent
import Redis
import Vapor
import VaporRedisUtils
import VaporUtils

public struct UserController: RestCrudController {
    public typealias DBModel = DBUser

    public struct DTO: Content {
        public var id: UUID
        public var roles: Set<String>
        public var isActive: Bool
    }

    public struct PostDTO: Content {
        public var roles: Set<String>
        public var isActive: Bool
    }

    public struct PatchDTO: Content {
        public var roles: Set<String>?
        public var isActive: Bool?
    }

    let rolesConverter: RolesConverter

    public init(rolesConverter: RolesConverter) {
        self.rolesConverter = rolesConverter
    }

    public func toDTO(_ dbModel: DBUser) throws -> DTO {
        try .init(
            id: dbModel.requireID(),
            roles: rolesConverter.toStrings(.init(rawValue: dbModel.roles)),
            isActive: dbModel.isActive,
        )
    }

    public var sortColumnMapping = [
        "roles": "roles",
        "isActive": "is_active",
    ]

    public func boot(routes: any RoutesBuilder) throws {
        let root = routes
            .grouped("v1", "users")
            .grouped(TokenAuthenticator())
            .grouped(AuthUser.guardMiddleware())
            .grouped(RequireAdminMiddleware())

        root.get(use: self.index)
        root.post(use: self.create { dto, _ in
            .init(
                roles: rolesConverter.toRoles(dto.roles).rawValue,
                isActive: dto.isActive
            )
        })
        root.group(":id") { route in
            route.get(use: self.get)
            route.patch(use: self.update)
            route.post("invalidateSessions", use: self.invalidateSessions)
        }
    }

    func update(req: Request) async throws -> DTO {
        let userID = try req.parameters.require("id", as: UUID.self)
        guard let dbModel = try await DBUser.find(userID, on: req.db) else {
            throw Abort(.notFound)
        }
        let patch = try req.content.decode(PatchDTO.self)

        var userAccessChanged = false
        if let value = patch.roles.map(rolesConverter.toRoles) {
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
                try await req.tokenClient.revokeAllActiveTokens(userID: userID, db: db)
            }
        } else {
            try await dbModel.save(on: req.db)
        }

        return updated
    }

    func invalidateSessions(req: Request) async throws -> HTTPStatus {
        let userID = try req.parameters.require("id", as: UUID.self)
        try await req.tokenClient.revokeAllActiveTokens(userID: userID)
        return .ok
    }
}
