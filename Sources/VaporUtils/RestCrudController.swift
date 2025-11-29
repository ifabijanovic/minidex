import Fluent
import FluentPostgresDriver
import Vapor

#if DEBUG
import FluentSQLiteDriver
#endif

public enum PagedResponseSort: String, Content {
    case ascending = "asc"
    case descending = "desc"

    var dbValue: DatabaseQuery.Sort.Direction {
        switch self {
        case .ascending: .ascending
        case .descending: .descending
        }
    }
}

public struct ListQueryParams: Content {
    public var q: String?
    public var page: Int?
    public var limit: Int?
    public var sort: String?
    public var order: PagedResponseSort?

    static let defaultLimit = 25
}

public struct PagedResponse<T: Content>: Content {
    public var data: [T]
    public var page: Int
    public var limit: Int
    public var sort: String?
    public var order: PagedResponseSort?
    public var query: String?
}

public protocol RestCrudController: RouteCollection, Sendable {
    associatedtype DBModel: Model where DBModel.IDValue == UUID
    associatedtype DTO: Content
    associatedtype PostDTO: Content
    associatedtype PatchDTO: Content

    /// Called by `get`, `update` and `delete` to find the model to operate on.
    /// Default implementation looks for `id` path parameter and looks up by
    /// primary key in database.
    func findOne(req: Request) async throws -> DBModel?

    /// Called by `index` to build the base query for fetching a list of
    /// models, before applying any filtering, sorting or pagination.
    /// Default implementation returns the default query for `DBModel`.
    func findMany(req: Request) -> QueryBuilder<DBModel>

    /// Mapping from `DTO` to `DBModel`, no default implementation.
    func toDTO(_ dbModel: DBModel) throws -> DTO

    /// Called by `index` when search parameter is provided.
    /// Default implementation does nothing, implement to support filtering.
    func indexFilter(_ q: String, query: QueryBuilder<DBModel>) -> QueryBuilder<DBModel>?

    /// Called by `index` when sort parameter is provided.
    /// Default implementation does nothing, implement to support sorting.
    func indexSort(
        _ sort: String,
        _ order: DatabaseQuery.Sort.Direction,
        query: QueryBuilder<DBModel>
    ) -> QueryBuilder<DBModel>?
}

extension RestCrudController {
    public var defaultLimit: Int { 25 }

    public func findOne(req: Request) async throws -> DBModel? {
        try await DBModel.find(req.parameters.require("id"), on: req.db)
    }

    private func findOneOrThrow(req: Request) async throws -> DBModel {
        guard let model = try await findOne(req: req) else { throw Abort(.notFound) }
        return model
    }

    public func findMany(req: Request) -> QueryBuilder<DBModel> {
        DBModel.query(on: req.db)
    }

    public func indexFilter(_ q: String, query: QueryBuilder<DBModel>) -> QueryBuilder<DBModel>? {
        nil
    }

    public func indexSort(
        _ sort: String,
        _ order: DatabaseQuery.Sort.Direction,
        query: QueryBuilder<DBModel>
    ) -> QueryBuilder<DBModel>? {
        nil
    }

    public func index(req: Request) async throws -> PagedResponse<DTO> {
        let params = try req.query.decode(ListQueryParams.self)

        var query = findMany(req: req)

        // Search
        if let filteredQuery = params.q.flatMap({ indexFilter($0, query: query) }) {
            query = filteredQuery
        }

        // Sort
        let sortOrder = params.order ?? .ascending
        if let sortedQuery = params.sort.flatMap({ indexSort($0.lowercased(), sortOrder.dbValue, query: query) }) {
            query = sortedQuery
        }

        // Pagination
        let page = params.page ?? 0
        let limit = min(
            params.limit ?? ListQueryParams.defaultLimit,
            req.db.context.pageSizeLimit ?? ListQueryParams.defaultLimit,
        )
        query = query.offset(page * limit).limit(limit)

        let data = try await query.all().map(toDTO)

        return .init(
            data: data,
            page: page,
            limit: limit,
            sort: params.sort?.lowercased(),
            order: params.sort != nil ? (params.order ?? .ascending) : nil,
            query: params.q,
        )
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
