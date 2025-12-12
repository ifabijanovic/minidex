import MiniDexDB
@testable import MiniDexServer
import Foundation
import Testing
import VaporTesting
import VaporTestingUtils
import VaporUtils

@Suite("Faction controller", .serialized)
struct FactionControllerTests {
    typealias DTO = FactionController.DTO
    typealias PatchDTO = FactionController.PatchDTO

    @Test("read factions with include query options")
    func readFactionsWithIncludes() async throws {
        try await AuthenticatedTestContext.run(
            migrations: MiniDexDB.migrations,
            roles: .cataloguer
        ) { context in
            let app = context.app
            try app.register(collection: FactionController())

            let gameSystem = DBGameSystem(name: "Warhammer 40k", createdByID: context.userID, visibility: .`public`)
            try await gameSystem.save(on: app.db)

            let parentFaction = DBFaction(
                name: "Space Marines",
                gameSystemID: try gameSystem.requireID(),
                createdByID: context.userID,
                visibility: .`public`
            )
            try await parentFaction.save(on: app.db)

            let faction = DBFaction(
                name: "Ultramarines",
                gameSystemID: try gameSystem.requireID(),
                parentFactionID: try parentFaction.requireID(),
                createdByID: context.userID,
                visibility: .`public`
            )
            try await faction.save(on: app.db)

            // No includes: related names should be nil
            try await app.testing().test(.GET, "/v1/factions", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: context.token)
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
                let response = try res.content.decode(PagedResponse<DTO>.self)
                #expect(response.data.count == 2)
                for dto in response.data {
                    #expect(dto.gameSystemName == nil)
                    #expect(dto.parentFactionName == nil)
                }
            })

            // Include only game system: gameSystemName present, parentFactionName nil
            try await app.testing().test(.GET, "/v1/factions?include=gameSystem", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: context.token)
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
                let response = try res.content.decode(PagedResponse<DTO>.self)
                #expect(response.data.count == 2)
                #expect(response.data.first?.gameSystemName == "Warhammer 40k")
                #expect(response.data.first?.parentFactionName == nil)
                #expect(response.data.last?.gameSystemName == "Warhammer 40k")
                #expect(response.data.last?.parentFactionName == nil)
            })

            // Include both: both names present
            try await app.testing().test(.GET, "/v1/factions?include=gameSystem,parentFaction", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: context.token)
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
                let response = try res.content.decode(PagedResponse<DTO>.self)
                #expect(response.data.count == 2)
                #expect(response.data.first?.gameSystemName == "Warhammer 40k")
                #expect(response.data.first?.parentFactionName == nil)
                #expect(response.data.last?.gameSystemName == "Warhammer 40k")
                #expect(response.data.last?.parentFactionName == "Space Marines")
            })

            try await faction.delete(on: app.db)
            try await parentFaction.delete(on: app.db)
        }
    }

    @Test("read single faction with include query options")
    func readSingleFactionWithIncludes() async throws {
        try await AuthenticatedTestContext.run(
            migrations: MiniDexDB.migrations,
            roles: .cataloguer
        ) { context in
            let app = context.app
            try app.register(collection: FactionController())

            let gameSystem = DBGameSystem(name: "Age of Sigmar", createdByID: context.userID, visibility: .`public`)
            try await gameSystem.save(on: app.db)

            let parentFaction = DBFaction(
                name: "Grand Alliance Order",
                gameSystemID: try gameSystem.requireID(),
                createdByID: context.userID,
                visibility: .`public`
            )
            try await parentFaction.save(on: app.db)

            let faction = DBFaction(
                name: "Stormcast Eternals",
                gameSystemID: try gameSystem.requireID(),
                parentFactionID: try parentFaction.requireID(),
                createdByID: context.userID,
                visibility: .`public`
            )
            try await faction.save(on: app.db)

            let factionID = try faction.requireID()

            // No includes: related names should be nil
            try await app.testing().test(.GET, "/v1/factions/\(factionID)", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: context.token)
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
                let dto = try res.content.decode(DTO.self)
                #expect(dto.gameSystemName == nil)
                #expect(dto.parentFactionName == nil)
            })

            // Include only game system
            try await app.testing().test(.GET, "/v1/factions/\(factionID)?include=gameSystem", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: context.token)
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
                let dto = try res.content.decode(DTO.self)
                #expect(dto.gameSystemName == "Age of Sigmar")
                #expect(dto.parentFactionName == nil)
            })

            // Include both
            try await app.testing().test(.GET, "/v1/factions/\(factionID)?include=gameSystem,parentFaction", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: context.token)
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
                let dto = try res.content.decode(DTO.self)
                #expect(dto.gameSystemName == "Age of Sigmar")
                #expect(dto.parentFactionName == "Grand Alliance Order")
            })

            try await faction.delete(on: app.db)
            try await parentFaction.delete(on: app.db)
        }
    }

    @Test("patching faction supports clearing relations")
    func updateGameSystemAndParentToNil() async throws {
        try await AuthenticatedTestContext.run(
            migrations: MiniDexDB.migrations,
            roles: .cataloguer
        ) { context in
            let app = context.app
            try app.register(collection: FactionController())

            let gameSystem = DBGameSystem(name: "Warhammer 40k", createdByID: context.userID, visibility: .`public`)
            try await gameSystem.save(on: app.db)

            let parentFaction = DBFaction(
                name: "Space Marines",
                gameSystemID: try gameSystem.requireID(),
                createdByID: context.userID,
                visibility: .`public`
            )
            try await parentFaction.save(on: app.db)

            let faction = DBFaction(
                name: "Cobalt Knights",
                gameSystemID: try gameSystem.requireID(),
                parentFactionID: try parentFaction.requireID(),
                createdByID: context.userID,
                visibility: .`public`
            )
            try await faction.save(on: app.db)

            try await app.testing().test(.PATCH, "/v1/factions/\(try faction.requireID())", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: context.token)
                try req.content.encode(
                    PatchDTO(gameSystemID: clearSentinelID, parentFactionID: clearSentinelID)
                )
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
                let dto = try res.content.decode(DTO.self)
                #expect(dto.gameSystemID == nil)
                #expect(dto.parentFactionID == nil)
            })

            try await app.testing().test(.PATCH, "/v1/factions/\(try faction.requireID())", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: context.token)
                try req.content.encode(
                    PatchDTO(gameSystemID: gameSystem.id, parentFactionID: parentFaction.id)
                )
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
                let dto = try res.content.decode(DTO.self)
                #expect(dto.gameSystemID == gameSystem.id)
                #expect(dto.parentFactionID == parentFaction.id)
            })

            try await faction.delete(on: app.db)
            try await parentFaction.delete(on: app.db)
        }
    }

    @Test("update parent to self fails")
    func updateParentToSelf() async throws {
        try await AuthenticatedTestContext.run(
            migrations: MiniDexDB.migrations,
            roles: .cataloguer
        ) { context in
            let app = context.app
            try app.register(collection: FactionController())

            let faction = DBFaction(
                name: "Space Marines",
                createdByID: context.userID,
                visibility: .`public`
            )
            try await faction.save(on: app.db)
            let factionID = try faction.requireID()

            try await app.testing().test(.PATCH, "/v1/factions/\(factionID)", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: context.token)
                try req.content.encode(PatchDTO(parentFactionID: factionID))
            }, afterResponse: { res async throws in
                #expect(res.status == .conflict)
            })
        }
    }

    @Test("read single faction with include query options")
    func deleteParentFaction() async throws {
        try await AuthenticatedTestContext.run(
            migrations: MiniDexDB.migrations,
            roles: .cataloguer
        ) { context in
            let app = context.app
            try app.register(collection: FactionController())

            let parentFaction = DBFaction(
                name: "Grand Alliance Order",
                createdByID: context.userID,
                visibility: .`public`
            )
            try await parentFaction.save(on: app.db)

            let faction = DBFaction(
                name: "Stormcast Eternals",
                parentFactionID: try parentFaction.requireID(),
                createdByID: context.userID,
                visibility: .`public`
            )
            try await faction.save(on: app.db)

            let parentFactionID = try parentFaction.requireID()

            try await app.testing().test(.DELETE, "/v1/factions/\(parentFactionID)", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: context.token)
            }, afterResponse: { res async throws in
                #expect(res.status == .conflict)
            })

            try await faction.delete(on: app.db)
        }
    }
}
