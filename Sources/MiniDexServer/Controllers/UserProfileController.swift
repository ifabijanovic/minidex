import AuthAPI
import Fluent
import MiniDexDB
import Vapor
import VaporUtils

struct UserProfile: Content {
    var id: UUID?
    var userID: UUID
    var displayName: String?
    var avatarURL: URL?
}

struct UserProfilePostIn: Content {
    var displayName: String?
    var avatarURL: URL?
}

struct UserProfilePatchIn: Content {
    var displayName: String?
    var avatarURL: URL?
}

struct UserProfileController: RouteCollection {
    let crud: ApiCrudController<DBUserProfile, UserProfile, UserProfilePostIn, UserProfilePatchIn> = .init(
        fetchBy: .oneToOneKey(\.$user.$id)
    ) {
        .init(
            id: $0.id,
            userID: $0.$user.id,
            displayName: $0.displayName,
            avatarURL: $0.avatarURL.flatMap(URL.init(string:)),
        )
    }

    func boot(routes: any RoutesBuilder) throws {
        routes
            .grouped("v1", "users")
            .group(":id") { route in
                let root = route
                    .grouped("profile")
                    .grouped(TokenAuthenticator())
                    .grouped(AuthUser.guardMiddleware())

                root.get(use: crud.get)

                let adminOnly = root.grouped(RequireAdminMiddleware())
                adminOnly.post(use: crud.create { dto, req in
                    try .init(
                        userID: req.parameters.require("id"),
                        displayName: dto.displayName,
                        avatarURL: dto.avatarURL?.absoluteString,
                    )
                })
                adminOnly.patch(use: crud.update { dbModel, patch in
                    if let value = patch.displayName { dbModel.displayName = value }
                    if let value = patch.avatarURL { dbModel.avatarURL = value.absoluteString }
                })
            }
    }
}
