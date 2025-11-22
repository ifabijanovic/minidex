import AuthAPI
import Fluent
import MiniDexDB
import Vapor
import VaporUtils

struct UserProfileController: RestCrudController {
    typealias DBModel = DBUserProfile

    struct DTO: Content {
        var id: UUID
        var userID: UUID
        var displayName: String?
        var avatarURL: URL?
    }

    struct PostDTO: Content {
        var displayName: String?
        var avatarURL: URL?
    }

    struct PatchDTO: Content {
        var displayName: String?
        var avatarURL: URL?
    }

    func findOne(req: Request) async throws -> DBModel? {
        try await DBUserProfile
            .query(on: req.db)
            .filter(\.$user.$id == req.parameters.require("id"))
            .first()
    }

    func toDTO(_ dbModel: DBUserProfile) throws -> DTO {
        try .init(
            id: dbModel.requireID(),
            userID: dbModel.$user.id,
            displayName: dbModel.displayName,
            avatarURL: dbModel.avatarURL.flatMap(URL.init(string:)),
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

                root.get(use: self.get)

                let adminOnly = root.grouped(RequireAdminMiddleware())
                adminOnly.post(use: self.create { dto, req in
                    try .init(
                        userID: req.parameters.require("id"),
                        displayName: dto.displayName,
                        avatarURL: dto.avatarURL?.absoluteString,
                    )
                })
                adminOnly.patch(use: self.update { dbModel, patch in
                    if let value = patch.displayName { dbModel.displayName = value }
                    if let value = patch.avatarURL { dbModel.avatarURL = value.absoluteString }
                })
            }
    }
}
