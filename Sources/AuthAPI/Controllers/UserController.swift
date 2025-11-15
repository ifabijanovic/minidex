import AuthDB
import Fluent
import Vapor
import VaporUtils

struct UserPatchIn: Content {
    public var displayName: String?
    public var roles: Roles?
    public var isActive: Bool?
}

public struct UserController: RouteCollection, Sendable {
    public init() {}

    let crud: ApiCrudController<DBUser, User, UserPatchIn> = .init(
        toDTO: {
            try .init(
                id: $0.requireID(),
                displayName: $0.displayName,
                roles: .init(rawValue: $0.roles),
                isActive: $0.isActive
            )
        },
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
            .grouped("api", "user")
            .grouped(TokenAuthenticator())
            .grouped(User.guardMiddleware())
            .grouped(RequireAdminMiddleware())

        root.group(":id") { route in
            route.patch(use: crud.update { model, patch in
                if let value = patch.displayName { model.displayName = value }
                if let value = patch.roles { model.roles = value.rawValue }
                if let value = patch.isActive { model.isActive = value }
            })
        }
    }
}
