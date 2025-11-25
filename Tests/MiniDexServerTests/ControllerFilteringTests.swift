import MiniDexDB
@testable import MiniDexServer
import Foundation
import Testing
import VaporTesting
import VaporTestingUtils
import VaporUtils

@Suite("ControllerFiltering", .serialized)
struct ControllerFilteringTests {
    typealias DTO = GameSystemController.DTO
    typealias PostDTO = GameSystemController.PostDTO
    typealias PatchDTO = GameSystemController.PatchDTO

    @Test("filtering searches by name contains")
    func filteringByName() async throws {
        try await AuthenticatedTestContext.run(
            migrations: MiniDexDB.migrations,
            roles: .cataloguer,
        ) { context in
            let app = context.app
            let token = context.token

            try app.register(collection: GameSystemController())

            // Create test data
            try await DBGameSystem(name: "Warhammer 40k").save(on: app.db)
            try await DBGameSystem(name: "Warhammer Fantasy").save(on: app.db)
            try await DBGameSystem(name: "Dungeons & Dragons").save(on: app.db)
            try await DBGameSystem(name: "Pathfinder").save(on: app.db)

            try await app.testing().test(.GET, "/v1/gamesystems?q=Warhammer", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: token)
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
                let response = try res.content.decode(PagedResponse<DTO>.self)
                #expect(response.query == "Warhammer")
                #expect(response.data.count == 2)
                #expect(response.data.allSatisfy { $0.name.contains("Warhammer") })
            })
        }
    }

    @Test("filtering returns empty results when no match")
    func filteringNoMatch() async throws {
        try await AuthenticatedTestContext.run(
            migrations: MiniDexDB.migrations,
            roles: .cataloguer,
        ) { context in
            let app = context.app
            let token = context.token

            try app.register(collection: GameSystemController())

            // Create test data
            try await DBGameSystem(name: "Warhammer 40k").save(on: app.db)
            try await DBGameSystem(name: "Dungeons & Dragons").save(on: app.db)

            try await app.testing().test(.GET, "/v1/gamesystems?q=Nonexistent", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: token)
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
                let response = try res.content.decode(PagedResponse<DTO>.self)
                #expect(response.query == "Nonexistent")
                #expect(response.data.isEmpty)
            })
        }
    }

    @Test("filtering is not case sensitive")
    func filteringNotCaseSensitive() async throws {
        try await AuthenticatedTestContext.run(
            migrations: MiniDexDB.migrations,
            roles: .cataloguer,
        ) { context in
            let app = context.app
            let token = context.token

            try app.register(collection: GameSystemController())

            // Create test data
            try await DBGameSystem(name: "Warhammer 40k").save(on: app.db)
            try await DBGameSystem(name: "warhammer fantasy").save(on: app.db)

            try await app.testing().test(.GET, "/v1/gamesystems?q=Warhammer", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: token)
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
                let response = try res.content.decode(PagedResponse<DTO>.self)
                // Should only match "Warhammer 40k" (case-sensitive)
                #expect(response.data.count == 2)
            })
        }
    }
}
