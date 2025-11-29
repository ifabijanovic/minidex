import AuthAPI
import Fluent
import MiniDexDB
import Vapor
import VaporUtils

struct MiniController: RestCrudController {
    typealias DBModel = DBMini

    struct DTO: Content {
        var id: UUID
        var name: String
        var gameSystemID: UUID
    }

    struct PostDTO: Content {
        var name: String
        var gameSystemID: UUID
    }

    struct PatchDTO: Content {
        var name: String?
        var gameSystemID: UUID?
    }

    func toDTO(_ dbModel: DBMini) throws -> DTO {
        try .init(
            id: dbModel.requireID(),
            name: dbModel.name,
            gameSystemID: dbModel.$gameSystem.id
        )
    }

    func indexFilter(_ q: String, query: QueryBuilder<DBMini>) -> QueryBuilder<DBMini>? {
        query.caseInsensitiveContains(\.$name, q)
    }

    func indexSort(
        _ sort: String,
        _ order: DatabaseQuery.Sort.Direction,
        query: QueryBuilder<DBGameSystem>
    ) -> QueryBuilder<DBGameSystem>? {
        switch sort {
        case "name":
            query.sort(\.$name, order)
        default:
            nil
        }
    }

    func boot(routes: any RoutesBuilder) throws {
        let root = routes
            .grouped("v1", "minis")
            .grouped(TokenAuthenticator())
            .grouped(AuthUser.guardMiddleware())
            .grouped(RequireAnyRolesMiddleware(roles: [.admin, .cataloguer]))

        root.get(use: self.index)
        root.post(use: self.create { dto, _ in
            .init(name: dto.name, gameSystemID: dto.gameSystemID)
        })
        root.group(":id") { route in
            route.get(use: self.get)
            route.patch(use: self.update { dbModel, patch in
                if let value = patch.name { dbModel.name = value }
                if let value = patch.gameSystemID { dbModel.$gameSystem.id = value }
            })
            route.delete(use: self.delete)
        }
    }
}
