import Fluent
import Vapor

public struct ApiCrudController<DBModel, DTO, PatchDTO>: Sendable
where
    DBModel: Model,
    DBModel.IDValue == UUID,
    DTO: Content,
    PatchDTO: Content
{
    let fetchQuery: FetchQuery
    let toDTO: @Sendable (DBModel) throws -> DTO
    let toModel: @Sendable (DTO) throws -> DBModel

    public enum FetchQuery: Sendable {
        case primaryKey
        case oneToOneKey(KeyPath<DBModel, FieldProperty<DBModel, UUID>>)
    }

    public init(
        fetchBy: FetchQuery = .primaryKey,
        toDTO: @Sendable @escaping (DBModel) throws -> DTO,
        toModel: @Sendable @escaping (DTO) throws -> DBModel,
    ) {
        self.fetchQuery = fetchBy
        self.toDTO = toDTO
        self.toModel = toModel
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
    public func create(req: Request) async throws -> DTO {
        let input = try req.content.decode(DTO.self)
        let dbModel = try toModel(input)
        try await dbModel.save(on: req.db)
        return try toDTO(dbModel)
    }

    @Sendable
    public func update(
        mutate: @Sendable @escaping (DBModel, PatchDTO) -> Void
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
