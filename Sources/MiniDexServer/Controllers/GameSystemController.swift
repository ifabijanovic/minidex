import MiniDexDB
import Fluent
import Vapor

struct GameSystem: Content {
    var id: UUID?
    var name: String
}

struct GameSystemController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let group = routes.grouped("api", "gamesystem")
        group.get(use: self.index)
        group.post(use: self.create)
    }

    @Sendable
    func index(req: Request) async throws -> [GameSystem] {
        try await DBGameSystem
            .query(on: req.db)
            .all()
            .map(GameSystem.init(db:))
    }

    @Sendable
    func create(req: Request) async throws -> GameSystem {
        let dbModel = try req.content.decode(GameSystem.self).toModel()
        try await dbModel.save(on: req.db)
        return .init(db: dbModel)
    }
}

extension GameSystem {
    init(db: DBGameSystem) {
        self.id = db.id
        self.name = db.name
    }

    func toModel() -> DBGameSystem {
        .init(id: id, name: name)
    }
}
