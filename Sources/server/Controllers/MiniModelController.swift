import db
import Fluent
import Vapor

struct MiniModel: Content {
    var id: UUID?
    var name: String
}

struct MiniModelPatch: Content {
    var name: String?
}

struct MiniModelController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let group = routes.grouped("api", "minimodel")
        group.get(use: self.index)
        group.post(use: self.create)
        group.group(":id") { route in
            route.get(use: self.get)
            route.patch(use: self.update)
            route.delete(use: self.delete)
        }
    }

    @Sendable
    func index(req: Request) async throws -> [MiniModel] {
        try await DBMiniModel
            .query(on: req.db)
            .all()
            .map(MiniModel.init(db:))
    }

    @Sendable
    func get(req: Request) async throws -> MiniModel {
        try await .init(db: findById(req: req))
    }

    @Sendable
    func create(req: Request) async throws -> MiniModel {
        let dbModel = try req.content.decode(MiniModel.self).toModel()
        try await dbModel.save(on: req.db)
        return .init(db: dbModel)
    }

    @Sendable
    func update(req: Request) async throws -> MiniModel {
        let dbModel = try await findById(req: req)
        let patch = try req.content.decode(MiniModelPatch.self)
        if let name = patch.name {
            dbModel.name = name
        }
        try await dbModel.save(on: req.db)
        return .init(db: dbModel)
    }

    @Sendable
    func delete(req: Request) async throws -> HTTPStatus {
        let dbModel = try await findById(req: req)
        try await dbModel.delete(on: req.db)
        return .ok
    }

    private func findById(req: Request) async throws -> DBMiniModel {
        if let dbModel = try await DBMiniModel.find(req.parameters.require("id"), on: req.db) {
            return dbModel
        }
        throw Abort(.notFound)
    }
}

extension MiniModel {
    init(db: DBMiniModel) {
        self.id = db.id
        self.name = db.name
    }

    func toModel() -> DBMiniModel {
        .init(id: id, name: name)
    }
}
