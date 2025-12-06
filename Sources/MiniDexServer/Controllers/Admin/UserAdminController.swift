import AuthDB
import AuthAPI
import Fluent
import MiniDexDB
import Vapor
import VaporUtils

struct UserAdminController: RestCrudController {
    typealias DBModel = DBUser

    struct DTO: Content {
        var userID: UUID
        var roles: Set<String>
        var isActive: Bool
        var profileID: UUID?
        var displayName: String?
        var avatarURL: URL?
    }

    struct PostDTO: Content {}
    struct PatchDTO: Content {}

    let rolesConverter: RolesConverter

    init(rolesConverter: RolesConverter) {
        self.rolesConverter = rolesConverter
    }

    func findMany(req: Request) throws -> QueryBuilder<DBUser> {
        DBUser
            .query(on: req.db)
            .join(DBUserProfile.self, on: \DBUser.$id == \DBUserProfile.$user.$id, method: .left)
    }

    func toDTO(_ dbModel: DBUser) throws -> DTO {
        let profile = try? dbModel.joined(DBUserProfile.self)
        return try .init(
            userID: dbModel.requireID(),
            roles: rolesConverter.toStrings(.init(rawValue: dbModel.roles)),
            isActive: dbModel.isActive,
            profileID: profile?.id,
            displayName: profile?.displayName,
            avatarURL: profile?.avatarURL.flatMap(URL.init(string:)),
        )
    }

    func indexFilter(_ q: String, query: QueryBuilder<DBUser>) -> QueryBuilder<DBUser>? {
        query.caseInsensitiveContains(DBUserProfile.self, \.$displayName, q)
    }

    func indexSort(
        _ sort: String,
        _ order: DatabaseQuery.Sort.Direction,
        query: QueryBuilder<DBUser>
    ) -> QueryBuilder<DBUser>? {
        switch sort {
        case "roles":
            query.sort(\.$roles, order)
        case "isactive":
            query.sort(\.$isActive, order)
        case "displayname":
            query.sort(DBUserProfile.self, \.$displayName, order)
        default:
            nil
        }
    }

    func boot(routes: any RoutesBuilder) throws {
        routes
            .grouped("v1", "admin", "users")
            .grouped(TokenAuthenticator())
            .grouped(AuthUser.guardMiddleware())
            .grouped(RequireAdminMiddleware())
            .get(use: self.index)
    }
}
