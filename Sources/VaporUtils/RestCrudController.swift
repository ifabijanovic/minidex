import Fluent
import FluentPostgresDriver
import Vapor

#if DEBUG
import FluentSQLiteDriver
#endif

public protocol RestCrudController: RouteCollection, Sendable {
    associatedtype DBModel: Model where DBModel.IDValue == UUID
    associatedtype DTO: Content
    associatedtype PostDTO: Content
    associatedtype PatchDTO: Content

    func findOne(req: Request) async throws -> DBModel?
    func toDTO(_ dbModel: DBModel) throws -> DTO
}

extension RestCrudController {
    public func findOne(req: Request) async throws -> DBModel? {
        try await DBModel.find(req.parameters.require("id"), on: req.db)
    }

    private func findOneOrThrow(req: Request) async throws -> DBModel {
        guard let model = try await findOne(req: req) else { throw Abort(.notFound) }
        return model
    }

    public func index(req: Request) async throws -> [DTO] {
        try await DBModel
            .query(on: req.db)
            .all()
            .map(toDTO)
    }

    public func get(req: Request) async throws -> DTO {
        try await toDTO(findOneOrThrow(req: req))
    }

    public func create(
        makeModel: @Sendable @escaping (PostDTO, Request) throws -> DBModel,
    )  -> @Sendable (Request) async throws -> DTO {
        return { req in
            let input = try req.content.decode(PostDTO.self)
            let dbModel = try makeModel(input, req)
#if DEBUG
            do {
                try await dbModel.save(on: req.db)
            } catch let error as PostgresError where error.code == .uniqueViolation {
                throw Abort(.conflict)
            } catch let error as SQLiteError where error.reason == .constraintUniqueFailed {
                throw Abort(.conflict)
            }
#else
            do {
                try await dbModel.save(on: req.db)
            } catch let error as PostgresError where error.code == .uniqueViolation {
                throw Abort(.conflict)
            }
#endif
            return try toDTO(dbModel)
        }
    }

    public func update(
        mutate: @Sendable @escaping (DBModel, PatchDTO) -> Void,
    ) -> @Sendable (Request) async throws -> DTO {
        return { req in
            let dbModel = try await findOneOrThrow(req: req)
            let patch = try req.content.decode(PatchDTO.self)
            mutate(dbModel, patch)
            try await dbModel.save(on: req.db)
            return try toDTO(dbModel)
        }
    }

    public func delete(req: Request) async throws -> HTTPStatus {
        let dbModel = try await findOneOrThrow(req: req)
        try await dbModel.delete(on: req.db)
        return .noContent
    }
}
