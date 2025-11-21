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

struct UserProfilePatchIn: Content {
    var displayName: String?
    var avatarURL: URL?
}

struct UserProfileController: RouteCollection {
    let crud: ApiCrudController<DBUserProfile, UserProfile, UserProfilePatchIn> = .init(
        fetchBy: .oneToOneKey(\.$user.$id),
        toDTO: {
            .init(
                id: $0.id,
                userID: $0.$user.id,
                displayName: $0.displayName,
                avatarURL: $0.avatarURL.flatMap(URL.init(string:)),
            )
        },
        toModel: {
            .init(
                id: $0.id,
                userID: $0.userID,
                displayName: $0.displayName,
                avatarURL: $0.avatarURL?.absoluteString,
            )
        }
    )

    func boot(routes: any RoutesBuilder) throws {
        routes
            .grouped("v1", "users")
            .group(":id") { route in
                let root = route
                    .grouped("profile")
                    .grouped(TokenAuthenticator())
                    .grouped(AuthUser.guardMiddleware())

                root.get(use: crud.get)
                root.post(use: crud.create)
                root.patch(use: crud.update { dbModel, patch in
                    if let value = patch.displayName { dbModel.displayName = value }
                    if let value = patch.avatarURL { dbModel.avatarURL = value.absoluteString }
                })
            }
    }
}
