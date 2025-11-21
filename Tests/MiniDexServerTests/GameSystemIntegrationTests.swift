@testable import MiniDexServer
import Foundation
import Testing
import VaporTesting

@Suite("GameSystem Integration", .serialized)
struct GameSystemIntegrationTests {
    @Test("cataloguer can CRUD game systems via API")
    func cataloguerCRUD() async throws {
        try await TestContext.withAuthenticatedContext(roles: .cataloguer) { context in
            let app = context.app
            let token = context.token

            var createdID: UUID?

            try await app.testing().test(.POST, "/v1/gamesystem", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: token)
                try req.content.encode(GameSystem(id: nil, name: "Warhammer"))
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
                let dto = try res.content.decode(GameSystem.self)
                createdID = dto.id
                #expect(dto.name == "Warhammer")
            })

            guard let id = createdID else {
                Issue.record("Game system not created")
                return
            }

            try await app.testing().test(.GET, "/v1/gamesystem", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: token)
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
                let list = try res.content.decode([GameSystem].self)
                #expect(list.contains(where: { $0.id == id }))
            })

            try await app.testing().test(.PATCH, "/v1/gamesystem/\(id)", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: token)
                try req.content.encode(["name": "Warhammer 40k"])
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
            })

            try await app.testing().test(.GET, "/v1/gamesystem/\(id)", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: token)
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
                let dto = try res.content.decode(GameSystem.self)
                #expect(dto.name == "Warhammer 40k")
            })

            try await app.testing().test(.DELETE, "/v1/gamesystem/\(id)", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: token)
            }, afterResponse: { res async throws in
                #expect(res.status == .noContent)
            })

            try await app.testing().test(.GET, "/v1/gamesystem", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: token)
            }, afterResponse: { res async throws in
                let list = try res.content.decode([GameSystem].self)
                #expect(list.contains(where: { $0.id == id }) == false)
            })
        }
    }
}
