import AuthAPI
import Fluent
import MiniDexDB
import Vapor
import VaporUtils

struct GameSystem: Content {
    var id: UUID?
    var name: String
}

struct GameSystemPostIn: Content {
    var name: String
}

struct GameSystemPatchIn: Content {
    var name: String?
}

struct GameSystemController: RouteCollection {
    let crud: ApiCrudController<DBGameSystem, GameSystem, GameSystemPostIn, GameSystemPatchIn> = .init {
            .init(id: $0.id, name: $0.name)
    }

    func boot(routes: any RoutesBuilder) throws {
        let root = routes
            .grouped("v1", "gamesystem")
            .grouped(TokenAuthenticator())
            .grouped(AuthUser.guardMiddleware())
            .grouped(RequireAnyRolesMiddleware(roles: [.admin, .cataloguer]))

        root.get(use: crud.index)
        root.post(use: crud.create { dto, _ in
            .init(name: dto.name)
        })
        root.group(":id") { route in
            route.get(use: crud.get)
            route.patch(use: crud.update { dbModel, patch in
                if let value = patch.name { dbModel.name = value }
            })
            route.delete(use: crud.delete)
        }
    }
}
