import AuthAPI
import Fluent
import MiniDexDB
import Vapor

struct Mini: Content {
    var id: UUID?
    var name: String
    var gameSystemID: UUID
}

struct MiniPatch: Content {
    var name: String?
    var gameSystemID: UUID?
}

struct MiniController: RouteCollection {
    let crud: ApiCrudController<DBMini, Mini, MiniPatch> = .init(
        toDTO: {
            .init(id: $0.id, name: $0.name, gameSystemID: $0.$gameSystem.id)
        },
        toModel: {
            .init(id: $0.id, name: $0.name, gameSystemID: $0.gameSystemID)
        }
    )

    func boot(routes: any RoutesBuilder) throws {
        let root = routes
            .grouped("api", "mini")
            .grouped(TokenAuthenticator())
            .grouped(User.guardMiddleware())

        root.get(use: crud.index)
        root.post(use: crud.create)
        root.group(":id") { route in
            route.get(use: crud.get)
            route.patch(use: crud.update { dbModel, patch in
                if let name = patch.name {
                    dbModel.name = name
                }
                if let gameSystemID = patch.gameSystemID {
                    dbModel.$gameSystem.id = gameSystemID
                }
            })
            route.delete(use: crud.delete)
        }
    }
}
