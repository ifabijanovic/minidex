import AuthAPI
import Fluent
import MiniDexDB
import Vapor
import VaporUtils

struct GameSystem: Content {
    var id: UUID?
    var name: String
}

struct GameSystemPatchIn: Content {
    var name: String?
}

struct GameSystemController: RouteCollection {
    let crud: ApiCrudController<DBGameSystem, GameSystem, GameSystemPatchIn> = .init(
        toDTO: {
            .init(id: $0.id, name: $0.name)
        },
        toModel: {
            .init(id: $0.id, name: $0.name)
        }
    )


    func boot(routes: any RoutesBuilder) throws {
        let root = routes
            .grouped("v1", "gamesystem")
            .grouped(TokenAuthenticator())
            .grouped(AuthUser.guardMiddleware())
            .grouped(RequireAnyRolesMiddleware(roles: [.admin, .cataloguer]))

        root.get(use: crud.index)
        root.post(use: crud.create)
        root.group(":id") { route in
            route.get(use: crud.get)
            route.patch(use: crud.update { dbModel, patch in
                if let value = patch.name { dbModel.name = value }
            })
            route.delete(use: crud.delete)
        }
    }
}
