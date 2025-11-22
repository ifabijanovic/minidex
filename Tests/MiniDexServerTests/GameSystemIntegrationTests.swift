import MiniDexDB
@testable import MiniDexServer
import Foundation
import Testing
import VaporTesting
import VaporTestingUtils

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

            try await app.testing().test(.POST, "/v1/gamesystem", beforeRequest: { req in
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

            try await app.testing().test(.GET, "/v1/gamesystem", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: token)
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
                let list = try res.content.decode([DTO].self)
                #expect(list.contains(where: { $0.id == id }))
            })

            try await app.testing().test(.PATCH, "/v1/gamesystem/\(id)", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: token)
                try req.content.encode(PatchDTO(name: "Warhammer 40k"))
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
            })

            try await app.testing().test(.GET, "/v1/gamesystem/\(id)", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: token)
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
                let dto = try res.content.decode(DTO.self)
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
                let list = try res.content.decode([DTO].self)
                #expect(list.contains(where: { $0.id == id }) == false)
            })
        }
    }
}
