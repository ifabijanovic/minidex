import Fluent
import FluentPostgresDriver
import Vapor

#if DEBUG
import FluentSQLiteDriver
#endif

public struct ApiCrudController<DBModel, DTO, PostDTO, PatchDTO>: Sendable
where
    DBModel: Model,
    DBModel.IDValue == UUID,
    DTO: Content,
    PostDTO: Content,
    PatchDTO: Content
{
    let fetchQuery: FetchQuery
    let toDTO: @Sendable (DBModel) throws -> DTO

    public enum FetchQuery: Sendable {
        case primaryKey
        case oneToOneKey(KeyPath<DBModel, FieldProperty<DBModel, UUID>>)
    }

    public init(
        fetchBy: FetchQuery = .primaryKey,
        toDTO: @Sendable @escaping (DBModel) throws -> DTO,
    ) {
        self.fetchQuery = fetchBy
        self.toDTO = toDTO
    }

    @Sendable
    public func index(req: Request) async throws -> [DTO] {
        try await DBModel
            .query(on: req.db)
            .all()
            .map(toDTO)
    }

    @Sendable
    public func get(req: Request) async throws -> DTO {
        try await toDTO(findById(req: req))
    }

    @Sendable
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

    @Sendable
    public func update(
        mutate: @Sendable @escaping (DBModel, PatchDTO) -> Void,
    ) -> @Sendable (Request) async throws -> DTO {
        return { req in
            let dbModel = try await findById(req: req)
            let patch = try req.content.decode(PatchDTO.self)
            mutate(dbModel, patch)
            try await dbModel.save(on: req.db)
            return try toDTO(dbModel)
        }
    }

    @Sendable
    public func delete(req: Request) async throws -> HTTPStatus {
        let dbModel = try await findById(req: req)
        try await dbModel.delete(on: req.db)
        return .noContent
    }

    private func findById(req: Request) async throws -> DBModel {
        let dbModel: DBModel?
        switch fetchQuery {
        case .primaryKey:
            dbModel = try await DBModel.find(req.parameters.require("id"), on: req.db)
        case .oneToOneKey(let path):
            dbModel = try await DBModel
                .query(on: req.db)
                .filter(path == req.parameters.require("id"))
                .first()
        }
        guard let dbModel else { throw Abort(.notFound) }
        return dbModel
    }
}
