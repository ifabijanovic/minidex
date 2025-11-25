import MiniDexDB
@testable import MiniDexServer
import Foundation
import Testing
import VaporTesting
import VaporTestingUtils
import VaporUtils

@Suite("GameSystem Integration", .serialized)
struct GameSystemIntegrationTests {
    typealias DTO = GameSystemController.DTO
    typealias PostDTO = GameSystemController.PostDTO
    typealias PatchDTO = GameSystemController.PatchDTO

    @Test("cataloguer can CRUD game systems via API")
    func cataloguerCRUD() async throws {
        try await AuthenticatedTestContext.run(
            migrations: MiniDexDB.migrations,
            roles: .cataloguer,
        ) { context in
            let app = context.app
            let token = context.token

            try app.register(collection: GameSystemController())

            var createdID: UUID?

            try await app.testing().test(.POST, "/v1/gamesystems", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: token)
                try req.content.encode(PostDTO(name: "Warhammer"))
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
                let dto = try res.content.decode(DTO.self)
                createdID = dto.id
                #expect(dto.name == "Warhammer")
            })

            guard let id = createdID else {
                Issue.record("Game system not created")
                return
            }

            try await app.testing().test(.GET, "/v1/gamesystems", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: token)
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
                let response = try res.content.decode(PagedResponse<DTO>.self)
                #expect(response.data.contains(where: { $0.id == id }))
            })

            try await app.testing().test(.PATCH, "/v1/gamesystems/\(id)", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: token)
                try req.content.encode(PatchDTO(name: "Warhammer 40k"))
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
            })

            try await app.testing().test(.GET, "/v1/gamesystems/\(id)", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: token)
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
                let dto = try res.content.decode(DTO.self)
                #expect(dto.name == "Warhammer 40k")
            })

            try await app.testing().test(.DELETE, "/v1/gamesystems/\(id)", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: token)
            }, afterResponse: { res async throws in
                #expect(res.status == .noContent)
            })

            try await app.testing().test(.GET, "/v1/gamesystems", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: token)
            }, afterResponse: { res async throws in
                let response = try res.content.decode(PagedResponse<DTO>.self)
                #expect(response.data.contains(where: { $0.id == id }) == false)
            })
        }
    }

    @Test("pagination, sorting, and filtering work together")
    func combinedPaginationSortingFiltering() async throws {
        try await AuthenticatedTestContext.run(
            migrations: MiniDexDB.migrations,
            roles: .cataloguer,
        ) { context in
            let app = context.app
            let token = context.token

            try app.register(collection: GameSystemController())

            // Create test data
            try await DBGameSystem(name: "Warhammer Alpha").save(on: app.db)
            try await DBGameSystem(name: "Warhammer Beta").save(on: app.db)
            try await DBGameSystem(name: "Warhammer Gamma").save(on: app.db)
            try await DBGameSystem(name: "Warhammer Delta").save(on: app.db)
            try await DBGameSystem(name: "Warhammer Epsilon").save(on: app.db)
            try await DBGameSystem(name: "Dungeons & Dragons").save(on: app.db)

            // filter by "Warhammer", sort by name descending, limit to 2, page 0
            try await app.testing().test(.GET, "/v1/gamesystems?q=Warhammer&sort=name&order=desc&limit=2&page=0", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: token)
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
                let response = try res.content.decode(PagedResponse<DTO>.self)
                #expect(response.query == "Warhammer")
                #expect(response.sort == "name")
                #expect(response.order == .descending)
                #expect(response.page == 0)
                #expect(response.limit == 2)
                #expect(response.data.count == 2)

                #expect(response.data[0].name == "Warhammer Gamma")
                #expect(response.data.last?.name == "Warhammer Epsilon")
            })

            // same filter and sort, page 1 and limit 3
            try await app.testing().test(.GET, "/v1/gamesystems?q=Warhammer&sort=name&order=desc&limit=3&page=1", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: token)
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
                let response = try res.content.decode(PagedResponse<DTO>.self)
                #expect(response.page == 1)
                #expect(response.limit == 3)
                #expect(response.data.count == 2)

                // Should be next two items in descending order
                #expect(response.data[0].name == "Warhammer Beta")
                #expect(response.data[1].name == "Warhammer Alpha")
            })
        }
    }
}
