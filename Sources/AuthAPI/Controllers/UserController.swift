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

    public func boot(routes: any RoutesBuilder) throws {
        let root = routes
            .grouped("api", "user")
            .grouped(TokenAuthenticator())
            .grouped(AuthUser.guardMiddleware())
            .grouped(RequireAdminMiddleware())

        root.group(":id") { route in
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

        var shouldInvalidateCache = false
        if let value = patch.displayName { dbModel.displayName = value }
        if let value = patch.roles {
            dbModel.roles = value.rawValue
            shouldInvalidateCache = true
        }
        if let value = patch.isActive {
            dbModel.isActive = value
            shouldInvalidateCache = true
        }

        let updated = try User(db: dbModel)
        if shouldInvalidateCache {
            try await req.db.transaction { db in
                try await dbModel.save(on: db)
                try await invalidateCache(userID: userID, db: db, redis: req.redisClient, logger: req.logger)
            }
        } else {
            try await dbModel.save(on: req.db)
        }

        return updated
    }

    @Sendable
    func revokeAccess(req: Request) async throws -> HTTPStatus {
        let userID = try req.parameters.require("id", as: UUID.self)
        let tokens = try await DBUserToken
            .query(on: req.db)
            .filter(\.$user.$id == userID)
            .all()

        for token in tokens {
            token.isRevoked = true
            try await token.save(on: req.db)
            await req.redisClient.invalidate(
                hashedAccessToken: token.value.base64URLEncodedString(),
                logger: req.logger
            )
        }

        return .ok
    }

    private func invalidateCache(
        userID: UUID,
        db: any Database,
        redis: any RedisClient,
        logger: Logger,
    ) async throws {
        let tokens = try await DBUserToken
            .query(on: db)
            .filter(\.$user.$id == userID)
            .all()

        for token in tokens {
            let hashed = token.value.base64URLEncodedString()
            await redis.invalidate(hashedAccessToken: hashed, logger: logger)
        }
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
