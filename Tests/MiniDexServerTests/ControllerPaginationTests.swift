import MiniDexDB
@testable import MiniDexServer
import Foundation
import Testing
import VaporTesting
import VaporTestingUtils
import VaporUtils

@Suite("ControllerPagination", .serialized)
struct ControllerPaginationTests {
    typealias DTO = GameSystemController.DTO
    typealias PostDTO = GameSystemController.PostDTO
    typealias PatchDTO = GameSystemController.PatchDTO

    @Test("pagination returns default limit when not specified")
    func paginationDefaultLimit() async throws {
        try await AuthenticatedTestContext.run(
            migrations: MiniDexDB.migrations,
            roles: .cataloguer,
        ) { context in
            let app = context.app
            let token = context.token

            try app.register(collection: GameSystemController())

            // Create more than default limit (25) items
            let totalItems = 30
            for i in 1...totalItems {
                let gameSystem = DBGameSystem(name: "System \(i)")
                try await gameSystem.save(on: app.db)
            }

            try await app.testing().test(.GET, "/v1/gamesystems", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: token)
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
                let response = try res.content.decode(PagedResponse<DTO>.self)
                #expect(response.page == 0)
                #expect(response.limit == 25) // default limit
                #expect(response.data.count == 25)
            })
        }
    }

    @Test("pagination respects custom limit")
    func paginationCustomLimit() async throws {
        try await AuthenticatedTestContext.run(
            migrations: MiniDexDB.migrations,
            roles: .cataloguer,
        ) { context in
            let app = context.app
            let token = context.token

            try app.register(collection: GameSystemController())

            // Create test data
            for i in 1...10 {
                let gameSystem = DBGameSystem(name: "System \(i)")
                try await gameSystem.save(on: app.db)
            }

            try await app.testing().test(.GET, "/v1/gamesystems?limit=5", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: token)
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
                let response = try res.content.decode(PagedResponse<DTO>.self)
                #expect(response.page == 0)
                #expect(response.limit == 5)
                #expect(response.data.count == 5)
            })
        }
    }

    @Test("pagination supports page offset")
    func paginationPageOffset() async throws {
        try await AuthenticatedTestContext.run(
            migrations: MiniDexDB.migrations,
            roles: .cataloguer,
        ) { context in
            let app = context.app
            let token = context.token

            try app.register(collection: GameSystemController())

            // Create test data
            var firstPageIds: [UUID] = []
            for i in 1...10 {
                let gameSystem = DBGameSystem(name: "System \(i)")
                try await gameSystem.save(on: app.db)
                if i <= 5 {
                    firstPageIds.append(try gameSystem.requireID())
                }
            }

            // Get first page
            var firstPageResponse: PagedResponse<DTO>?
            try await app.testing().test(.GET, "/v1/gamesystems?limit=5&page=0", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: token)
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
                firstPageResponse = try res.content.decode(PagedResponse.self)
            })

            guard let firstPage = firstPageResponse else {
                Issue.record("First page response missing")
                return
            }

            #expect(firstPage.page == 0)
            #expect(firstPage.limit == 5)
            #expect(firstPage.data.count == 5)

            // Get second page
            var secondPageResponse: PagedResponse<DTO>?
            try await app.testing().test(.GET, "/v1/gamesystems?limit=5&page=1", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: token)
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
                secondPageResponse = try res.content.decode(PagedResponse.self)
            })

            guard let secondPage = secondPageResponse else {
                Issue.record("Second page response missing")
                return
            }

            #expect(secondPage.page == 1)
            #expect(secondPage.limit == 5)
            #expect(secondPage.data.count == 5)

            // Verify pages don't overlap
            let firstPageIdsSet = Set(firstPage.data.map { $0.id })
            let secondPageIdsSet = Set(secondPage.data.map { $0.id })
            #expect(firstPageIdsSet.isDisjoint(with: secondPageIdsSet))
        }
    }
}
