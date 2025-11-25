import AuthAPI
import Fluent
import MiniDexDB
import Vapor
import VaporUtils

struct GameSystemController: RestCrudController {
    typealias DBModel = DBGameSystem

    struct DTO: Content {
        var id: UUID
        var name: String
    }

    struct PostDTO: Content {
        var name: String
    }

    struct PatchDTO: Content {
        var name: String?
    }

    func toDTO(_ dbModel: DBGameSystem) throws -> DTO {
        try .init(
            id: dbModel.requireID(),
            name: dbModel.name,
        )
    }

    func indexFilter(_ q: String, query: QueryBuilder<DBGameSystem>) -> QueryBuilder<DBGameSystem>? {
        query.filter(\.$name ~~ q) // contains
    }

    var sortColumnMapping = [
        "name": "name",
    ]

    func boot(routes: any RoutesBuilder) throws {
        let root = routes
            .grouped("v1", "gamesystems")
            .grouped(TokenAuthenticator())
            .grouped(AuthUser.guardMiddleware())
            .grouped(RequireAnyRolesMiddleware(roles: [.admin, .cataloguer]))

        root.get(use: self.index)
        root.post(use: self.create { dto, _ in
            .init(name: dto.name)
        })
        root.group(":id") { route in
            route.get(use: self.get)
            route.patch(use: self.update { dbModel, patch in
                if let value = patch.name { dbModel.name = value }
            })
            route.delete(use: self.delete)
        }
    }
}
