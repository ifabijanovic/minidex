import AuthAPI
import Fluent
import MiniDexDB
import Vapor
import VaporUtils

struct Mini: Content {
    var id: UUID?
    var name: String
    var gameSystemID: UUID
}

struct MiniPatchIn: Content {
    var name: String?
    var gameSystemID: UUID?
}

struct MiniController: RouteCollection {
    let crud: ApiCrudController<DBMini, Mini, MiniPatchIn> = .init(
        toDTO: {
            .init(id: $0.id, name: $0.name, gameSystemID: $0.$gameSystem.id)
        },
        toModel: {
            .init(id: $0.id, name: $0.name, gameSystemID: $0.gameSystemID)
        }
    )

    func boot(routes: any RoutesBuilder) throws {
        let root = routes
            .grouped("v1", "mini")
            .grouped(TokenAuthenticator())
            .grouped(AuthUser.guardMiddleware())
            .grouped(RequireAnyRolesMiddleware(roles: [.admin, .cataloguer]))

        root.get(use: crud.index)
        root.post(use: crud.create)
        root.group(":id") { route in
            route.get(use: crud.get)
            route.patch(use: crud.update { dbModel, patch in
                if let value = patch.name { dbModel.name = value }
                if let value = patch.gameSystemID { dbModel.$gameSystem.id = value }
            })
            route.delete(use: crud.delete)
        }
    }
}
