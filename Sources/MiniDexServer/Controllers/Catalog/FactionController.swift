import AuthDB
import AuthAPI
import Fluent
import MiniDexDB
import Vapor
import VaporUtils

struct FactionController: RestCrudController {
    typealias DBModel = DBFaction

    struct DTO: Content {
        var id: UUID
        var name: String
        var gameSystemID: UUID?
        var gameSystemName: String?
        var parentFactionID: UUID?
        var parentFactionName: String?
        var createdByID: UUID
        var visibility: CatalogItemVisibility
    }

    struct PostDTO: Content {
        var name: String
        var gameSystemID: UUID?
        var parentFactionID: UUID?
        var visibility: CatalogItemVisibility
    }

    struct PatchDTO: Content {
        var name: String?
        var gameSystemID: UUID?
        var parentFactionID: UUID?
        var visibility: CatalogItemVisibility?
    }

    enum Includes: String, Codable, Sendable {
        case gameSystem
        case parentFaction
    }

    func findOne(req: Request) async throws -> DBFaction? {
        return try await findOneCatalogItem(
            req: req,
            userPath: \.$createdBy,
            visibilityPath: \.visibility
        ) { id in
            try findMany(req: req).filter(\.$id == id)
        }
    }

    func findMany(req: Request) throws -> QueryBuilder<DBFaction> {
        var query = try findManyCatalogItems(req: req, userPath: \.$createdBy, visibilityPath: \.$visibility)

        let params = try req.query.decode(ReadQuery<Includes>.self)
        if params.include?.contains(.gameSystem) == true {
            query = query.join(
                DBGameSystem.self,
                on: \DBFaction.$gameSystem.$id == \DBGameSystem.$id,
                method: .left,
            )
        }
        if params.include?.contains(.parentFaction) == true {
            query = query.join(
                DBParentFaction.self,
                on: \DBFaction.$parentFaction.$id == \DBParentFaction.$id,
                method: .left,
            )
        }

        return query
    }

    func toDTO(_ dbModel: DBFaction) throws -> DTO {
        let dbGameSystem = try? dbModel.joined(DBGameSystem.self)
        let dbParentFaction = try? dbModel.joined(DBParentFaction.self)
        return try .init(
            id: dbModel.requireID(),
            name: dbModel.name,
            gameSystemID: dbModel.$gameSystem.id,
            gameSystemName: dbGameSystem?.$name.value,
            parentFactionID: dbModel.$parentFaction.id,
            parentFactionName: dbParentFaction?.$name.value,
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
        query: QueryBuilder<DBFaction>
    ) -> QueryBuilder<DBFaction>? {
        switch sort {
        case "name":
            query.sort(\.$name, order)
        case "gamesystemname":
            query.sort(DBGameSystem.self, \.$name, order)
        case "parentfactionname":
            query.sort(DBParentFaction.self, \.$name, order)
        case "visibility":
            query.sort(\.$visibility, order)
        default:
            nil
        }
    }

    func boot(routes: any RoutesBuilder) throws {
        let root = routes
            .grouped("v1", "factions")
            .grouped(TokenAuthenticator())
            .grouped(AuthUser.guardMiddleware())

        root.get(use: self.index)
        root.post(use: self.createCatalogItem(\.visibility) { dto, req in
            return .init(
                name: dto.name,
                gameSystemID: dto.gameSystemID,
                parentFactionID: dto.parentFactionID,
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
                    if let value = patch.gameSystemID { dbModel.$gameSystem.id = value }
                    if let value = patch.parentFactionID { dbModel.$parentFaction.id = value }
                    if let value = patch.visibility { dbModel.visibility = value }
                }
            )
            route.delete(use: deleteCatalogItem(createdByPath: \.$createdBy, visibilityPath: \.visibility))
        }
    }
}
