import MiniDexDB
@testable import MiniDexServer
import Foundation
import Testing
import VaporTesting
import VaporTestingUtils
import VaporUtils

@Suite("ControllerSorting", .serialized)
struct ControllerSortingTests {
    typealias DTO = GameSystemController.DTO
    typealias PostDTO = GameSystemController.PostDTO
    typealias PatchDTO = GameSystemController.PatchDTO

    @Test("sorting defaults to ascending order")
    func sortingDefaultAscending() async throws {
        try await AuthenticatedTestContext.run(
            migrations: MiniDexDB.migrations,
            roles: .cataloguer,
        ) { context in
            let app = context.app
            let token = context.token

            try app.register(collection: GameSystemController())

            // Create test data in reverse order
            try await DBGameSystem(name: "Zebra System").save(on: app.db)
            try await DBGameSystem(name: "Alpha System").save(on: app.db)
            try await DBGameSystem(name: "Beta System").save(on: app.db)

            try await app.testing().test(.GET, "/v1/gamesystems?sort=name", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: token)
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
                let response = try res.content.decode(PagedResponse<DTO>.self)
                #expect(response.sort == "name")
                #expect(response.order == .ascending)

                let names = response.data.map { $0.name }
                #expect(names == names.sorted())
            })
        }
    }

    @Test("sorting supports ascending order explicitly")
    func sortingAscending() async throws {
        try await AuthenticatedTestContext.run(
            migrations: MiniDexDB.migrations,
            roles: .cataloguer,
        ) { context in
            let app = context.app
            let token = context.token

            try app.register(collection: GameSystemController())

            // Create test data
            try await DBGameSystem(name: "Zebra System").save(on: app.db)
            try await DBGameSystem(name: "Alpha System").save(on: app.db)
            try await DBGameSystem(name: "Beta System").save(on: app.db)

            try await app.testing().test(.GET, "/v1/gamesystems?sort=Name&order=asc", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: token)
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
                let response = try res.content.decode(PagedResponse<DTO>.self)
                #expect(response.sort == "name")
                #expect(response.order == .ascending)

                let names = response.data.map { $0.name }
                #expect(names == names.sorted())
            })
        }
    }

    @Test("sorting supports descending order")
    func sortingDescending() async throws {
        try await AuthenticatedTestContext.run(
            migrations: MiniDexDB.migrations,
            roles: .cataloguer,
        ) { context in
            let app = context.app
            let token = context.token

            try app.register(collection: GameSystemController())

            // Create test data
            try await DBGameSystem(name: "Alpha System").save(on: app.db)
            try await DBGameSystem(name: "Beta System").save(on: app.db)
            try await DBGameSystem(name: "Zebra System").save(on: app.db)

            try await app.testing().test(.GET, "/v1/gamesystems?sort=name&order=desc", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: token)
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
                let response = try res.content.decode(PagedResponse<DTO>.self)
                #expect(response.sort == "name")
                #expect(response.order == .descending)

                let names = response.data.map { $0.name }
                #expect(names == names.sorted(by: >))
            })
        }
    }
}
