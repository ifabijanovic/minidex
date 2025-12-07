import AuthDB
import AuthAPI
import Fluent
import MiniDexDB
import Vapor
import VaporUtils

struct GameSystemController: RestCrudController {
    typealias DBModel = DBGameSystem

    struct DTO: Content {
        var id: UUID
        var name: String
        var publisher: String?
        var releaseYear: UInt?
        var website: URL?
        var createdByID: UUID
        var visibility: CatalogItemVisibility
    }

    struct PostDTO: Content {
        var name: String
        var publisher: String?
        var releaseYear: UInt?
        var website: URL?
        var visibility: CatalogItemVisibility
    }

    struct PatchDTO: Content {
        var name: String?
        var publisher: String?
        var releaseYear: UInt?
        var website: URL?
        var visibility: CatalogItemVisibility?
    }

    func findOne(req: Request) async throws -> DBGameSystem? {
        try await findOneCatalogItem(req: req, userPath: \.$createdBy, visibilityPath: \.visibility)
    }

    func findMany(req: Request) throws -> QueryBuilder<DBGameSystem> {
        try findManyCatalogItems(req: req, userPath: \.$createdBy, visibilityPath: \.$visibility)
    }

    func toDTO(_ dbModel: DBGameSystem) throws -> DTO {
        try .init(
            id: dbModel.requireID(),
            name: dbModel.name,
            publisher: dbModel.publisher,
            releaseYear: dbModel.releaseYear,
            website: dbModel.website.flatMap(URL.init(string:)),
            createdByID: dbModel.$createdBy.id,
            visibility: dbModel.visibility,
        )
    }

    func indexFilter(_ q: String, query: QueryBuilder<DBGameSystem>) -> QueryBuilder<DBGameSystem>? {
        query.caseInsensitiveContains(\.$name, q)
    }

    func indexSort(
        _ sort: String,
        _ order: DatabaseQuery.Sort.Direction,
        query: QueryBuilder<DBGameSystem>
    ) -> QueryBuilder<DBGameSystem>? {
        switch sort {
        case "name":
            query.sort(\.$name, order)
        case "publisher":
            query.sort(\.$publisher, order)
        case "releaseyear":
            query.sort(\.$releaseYear, order)
        case "visibility":
            query.sort(\.$visibility, order)
        default:
            nil
        }
    }

    func boot(routes: any RoutesBuilder) throws {
        let root = routes
            .grouped("v1", "game-systems")
            .grouped(TokenAuthenticator())
            .grouped(AuthUser.guardMiddleware())

        root.get(use: self.index)
        root.post(use: self.createCatalogItem(\.visibility) { dto, req in
            return .init(
                name: dto.name,
                publisher: dto.publisher,
                releaseYear: dto.releaseYear,
                website: dto.website?.absoluteString,
                createdByID: try req.auth.require(AuthUser.self).id,
                visibility: dto.visibility,
            )
        })
        root.group(":id") { route in
            route.get(use: self.get)
            route.patch(
                use: self.updateCatalogItem(
                    createdByPath: \.$createdBy,
                    visibilityDBPath: \.visibility,
                    visibilityDTOPath: \.visibility,
                ) { dbModel, patch, _ in
                    if let value = patch.name { dbModel.name = value }
                    if let value = patch.publisher { dbModel.publisher = value }
                    if let value = patch.releaseYear { dbModel.releaseYear = value }
                    if let value = patch.website { dbModel.website = value.absoluteString }
                    if let value = patch.visibility { dbModel.visibility = value }
                }
            )
            route.delete(use: deleteCatalogItem(createdByPath: \.$createdBy, visibilityPath: \.visibility))
        }
    }
}
