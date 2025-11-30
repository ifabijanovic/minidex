import AuthDB
import Fluent
import Redis
import Vapor
import VaporRedisUtils
import VaporUtils

public struct UserController: RouteCollection, Sendable {
    public struct DTO: Content {
        public var id: UUID
        public var roles: Set<String>
        public var isActive: Bool
    }

    public struct PatchDTO: Content {
        public var roles: Set<String>?
        public var isActive: Bool?
    }

    let cacheExpiration: TimeInterval
    let checksumSecret: String
    let rolesConverter: RolesConverter

    public init(
        cacheExpiration: TimeInterval,
        checksumSecret: String,
        rolesConverter: RolesConverter,
    ) {
        self.cacheExpiration = cacheExpiration
        self.checksumSecret = checksumSecret
        self.rolesConverter = rolesConverter
    }

    public func boot(routes: any RoutesBuilder) throws {
        let root = routes
            .grouped("v1", "admin", "users")
            .grouped(TokenAuthenticator(cacheExpiration: cacheExpiration, checksumSecret: checksumSecret))
            .grouped(AuthUser.guardMiddleware())
            .grouped(RequireAdminMiddleware())

        root.group(":id") { route in
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

        let updated = try DTO(
            id: dbModel.requireID(),
            roles: rolesConverter.toStrings(.init(rawValue: dbModel.roles)),
            isActive: dbModel.isActive,
        )

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
