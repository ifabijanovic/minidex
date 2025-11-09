import MiniDexDB
import Fluent
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
    func boot(routes: any RoutesBuilder) throws {
        let group = routes.grouped("api", "mini")
        group.get(use: self.index)
        group.post(use: self.create)
        group.group(":id") { route in
            route.get(use: self.get)
            route.patch(use: self.update)
            route.delete(use: self.delete)
        }
    }

    @Sendable
    func index(req: Request) async throws -> [Mini] {
        try await DBMini
            .query(on: req.db)
            .all()
            .map(Mini.init(db:))
    }

    @Sendable
    func get(req: Request) async throws -> Mini {
        try await .init(db: findById(req: req))
    }

    @Sendable
    func create(req: Request) async throws -> Mini {
        let dbModel = try req.content.decode(Mini.self).toModel()
        try await dbModel.save(on: req.db)
        return .init(db: dbModel)
    }

    @Sendable
    func update(req: Request) async throws -> Mini {
        let dbModel = try await findById(req: req)
        let patch = try req.content.decode(MiniPatch.self)
        if let name = patch.name {
            dbModel.name = name
        }
        if let gameSystemID = patch.gameSystemID {
            dbModel.$gameSystem.id = gameSystemID
        }
        try await dbModel.save(on: req.db)
        return .init(db: dbModel)
    }

    @Sendable
    func delete(req: Request) async throws -> HTTPStatus {
        let dbModel = try await findById(req: req)
        try await dbModel.delete(on: req.db)
        return .noContent
    }

    private func findById(req: Request) async throws -> DBMini {
        if let dbModel = try await DBMini.find(req.parameters.require("id"), on: req.db) {
            return dbModel
        }
        throw Abort(.notFound)
    }
}

extension Mini {
    init(db: DBMini) {
        self.id = db.id
        self.name = db.name
        self.gameSystemID = db.$gameSystem.id
    }

    func toModel() -> DBMini {
        .init(id: id, name: name, gameSystemID: gameSystemID)
    }
}
