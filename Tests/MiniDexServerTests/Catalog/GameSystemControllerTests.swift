import MiniDexDB
@testable import MiniDexServer
import Foundation
import Testing
import VaporTesting
import VaporTestingUtils
import VaporUtils

@Suite("GameSystem controller", .serialized)
struct GameSystemControllerTests {
    typealias DTO = GameSystemController.DTO
    typealias PostDTO = GameSystemController.PostDTO
    typealias PatchDTO = GameSystemController.PatchDTO

    @Test("anonymous users are rejected")
    func anonymousRejected() async throws {
        try await TestContext.run(migrations: MiniDexDB.migrations) { context in
            let app = context.app
            try app.register(collection: GameSystemController())

            try await app.testing().test(.GET, "/v1/game-systems") { res async throws in
                #expect(res.status == .unauthorized)
            }

            try await app.testing().test(.POST, "/v1/game-systems") { res async throws in
                #expect(res.status == .unauthorized)
            }
        }
    }

    @Test("create game system as admin")
    func createAdmin() async throws {
        // Admin can create all visibilities
        try await AuthenticatedTestContext.run(
            migrations: MiniDexDB.migrations,
            roles: .admin
        ) { context in
            let app = context.app
            try app.register(collection: GameSystemController())

            for visibility in CatalogItemVisibility.allCases {
                try await app.testing().test(.POST, "/v1/game-systems", beforeRequest: { req in
                    req.headers.bearerAuthorization = .init(token: context.token)
                    try req.content.encode(PostDTO(name: "Admin \(visibility)", visibility: visibility))
                }, afterResponse: { res async throws in
                    #expect(res.status == .ok)
                    let dto = try res.content.decode(DTO.self)
                    #expect(dto.createdByID == context.userID)
                    #expect(dto.visibility == visibility)
                })
            }
        }
    }

    @Test("create game system as cataloguer")
    func createCataloguer() async throws {
        // Cataloguer can create private and public, but not limited
        try await AuthenticatedTestContext.run(
            migrations: MiniDexDB.migrations,
            roles: .cataloguer
        ) { context in
            let app = context.app
            try app.register(collection: GameSystemController())

            try await app.testing().test(.POST, "/v1/game-systems", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: context.token)
                try req.content.encode(PostDTO(name: "Cataloguer Private", visibility: .`private`))
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
                let dto = try res.content.decode(DTO.self)
                #expect(dto.createdByID == context.userID)
                #expect(dto.visibility == .`private`)
            })

            try await app.testing().test(.POST, "/v1/game-systems", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: context.token)
                try req.content.encode(PostDTO(name: "Cataloguer Public", visibility: .`public`))
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
                let dto = try res.content.decode(DTO.self)
                #expect(dto.createdByID == context.userID)
                #expect(dto.visibility == .`public`)
            })

            try await app.testing().test(.POST, "/v1/game-systems", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: context.token)
                try req.content.encode(PostDTO(name: "Cataloguer Limited", visibility: .limited))
            }, afterResponse: { res async throws in
                #expect(res.status == .forbidden)
            })
        }
    }

    @Test("create game system as hobbyist")
    func createHobbyist() async throws {
        // Hobbyist can create private and limited, but not public
        try await AuthenticatedTestContext.run(
            migrations: MiniDexDB.migrations,
            roles: .hobbyist
        ) { context in
            let app = context.app
            try app.register(collection: GameSystemController())

            try await app.testing().test(.POST, "/v1/game-systems", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: context.token)
                try req.content.encode(PostDTO(name: "Hobbyist Private", visibility: .`private`))
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
                let dto = try res.content.decode(DTO.self)
                #expect(dto.createdByID == context.userID)
                #expect(dto.visibility == .`private`)
            })

            try await app.testing().test(.POST, "/v1/game-systems", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: context.token)
                try req.content.encode(PostDTO(name: "Hobbyist Limited", visibility: .limited))
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
                let dto = try res.content.decode(DTO.self)
                #expect(dto.createdByID == context.userID)
                #expect(dto.visibility == .`limited`)
            })

            try await app.testing().test(.POST, "/v1/game-systems", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: context.token)
                try req.content.encode(PostDTO(name: "Hobbyist Public", visibility: .`public`))
            }, afterResponse: { res async throws in
                #expect(res.status == .forbidden)
            })
        }
    }

    @Test("read game systems as cataloguer")
    func readCataloguer() async throws {
        try await AuthenticatedTestContext.run(
            migrations: MiniDexDB.migrations,
            username: "misty",
            roles: .cataloguer
        ) { context in
            let app = context.app
            try app.register(collection: GameSystemController())

            // another user
            let other = try await AuthenticatedTestContext.createUser(
                on: app.db,
                username: "brock",
                roles: .hobbyist
            )
            let otherID = try other.requireID()

            let ownPrivate = DBGameSystem(name: "Misty Private", createdByID: context.userID, visibility: .`private`)
            try await ownPrivate.save(on: app.db)
            let othersPrivate = DBGameSystem(name: "Brock Private", createdByID: otherID, visibility: .`private`)
            try await othersPrivate.save(on: app.db)
            let othersLimited = DBGameSystem(name: "Brock Limited", createdByID: otherID, visibility: .limited)
            try await othersLimited.save(on: app.db)
            let publicItem = DBGameSystem(name: "Public Item", createdByID: otherID, visibility: .`public`)
            try await publicItem.save(on: app.db)

            try await app.testing().test(.GET, "/v1/game-systems", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: context.token)
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
                let response = try res.content.decode(PagedResponse<DTO>.self)
                let ids = Set(response.data.map { $0.id })
                #expect(ids.contains(try ownPrivate.requireID()))
                #expect(ids.contains(try publicItem.requireID()))
                #expect(ids.contains(try othersPrivate.requireID()) == false)
                #expect(ids.contains(try othersLimited.requireID()))
            })

            try await app.testing().test(.GET, "/v1/game-systems/\(ownPrivate.requireID())", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: context.token)
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
            })

            try await app.testing().test(.GET, "/v1/game-systems/\(othersPrivate.requireID())", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: context.token)
            }, afterResponse: { res async throws in
                #expect(res.status == .notFound)
            })

            try await app.testing().test(.GET, "/v1/game-systems/\(othersLimited.requireID())", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: context.token)
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
            })

            try await app.testing().test(.GET, "/v1/game-systems/\(publicItem.requireID())", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: context.token)
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
            })
        }
    }

    @Test("read game systems as hobbyist")
    func readHobbyist() async throws {
        try await AuthenticatedTestContext.run(
            migrations: MiniDexDB.migrations,
            username: "Dawn",
            roles: .hobbyist
        ) { context in
            let app = context.app
            try app.register(collection: GameSystemController())

            let other = try await AuthenticatedTestContext.createUser(
                on: app.db,
                username: "Iris",
                roles: .hobbyist
            )
            let otherID = try other.requireID()

            let ownPrivate = DBGameSystem(name: "Dawn Private", createdByID: context.userID, visibility: .`private`)
            try await ownPrivate.save(on: app.db)
            let ownLimited = DBGameSystem(name: "Dawn Limited", createdByID: context.userID, visibility: .limited)
            try await ownLimited.save(on: app.db)
            let ownPublic = DBGameSystem(name: "Dawn Public", createdByID: otherID, visibility: .`public`)
            try await ownPublic.save(on: app.db)
            let othersPrivate = DBGameSystem(name: "Iris Private", createdByID: otherID, visibility: .`private`)
            try await othersPrivate.save(on: app.db)
            let othersLimited = DBGameSystem(name: "Iris Limited", createdByID: otherID, visibility: .limited)
            try await othersLimited.save(on: app.db)
            let othersPublic = DBGameSystem(name: "Iris Public", createdByID: otherID, visibility: .`public`)
            try await othersPublic.save(on: app.db)

            try await app.testing().test(.GET, "/v1/game-systems", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: context.token)
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
                let response = try res.content.decode(PagedResponse<DTO>.self)
                let ids = Set(response.data.map { $0.id })
                #expect(ids.contains(try ownPrivate.requireID()))
                #expect(ids.contains(try ownLimited.requireID()))
                #expect(ids.contains(try ownPublic.requireID()))
                #expect(ids.contains(try othersPrivate.requireID()) == false)
                #expect(ids.contains(try othersLimited.requireID()) == false)
                #expect(ids.contains(try othersPublic.requireID()))
            })

            try await app.testing().test(.GET, "/v1/game-systems/\(try ownPrivate.requireID())", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: context.token)
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
            })

            try await app.testing().test(.GET, "/v1/game-systems/\(try ownLimited.requireID())", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: context.token)
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
            })

            try await app.testing().test(.GET, "/v1/game-systems/\(try ownPublic.requireID())", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: context.token)
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
            })

            try await app.testing().test(.GET, "/v1/game-systems/\(try othersPrivate.requireID())", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: context.token)
            }, afterResponse: { res async throws in
                #expect(res.status == .notFound)
            })

            try await app.testing().test(.GET, "/v1/game-systems/\(try othersLimited.requireID())", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: context.token)
            }, afterResponse: { res async throws in
                #expect(res.status == .notFound)
            })

            try await app.testing().test(.GET, "/v1/game-systems/\(try othersPublic.requireID())", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: context.token)
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
            })
        }
    }

    @Test("update game system as cataloguer")
    func updateCataloguer() async throws {
        try await AuthenticatedTestContext.run(
            migrations: MiniDexDB.migrations,
            username: "gary",
            roles: .cataloguer
        ) { context in
            let app = context.app
            try app.register(collection: GameSystemController())

            let other = try await AuthenticatedTestContext.createUser(
                on: app.db,
                username: "serena",
                roles: .hobbyist
            )
            let otherID = try other.requireID()

            let ownPrivate = DBGameSystem(name: "Gary Private", createdByID: context.userID, visibility: .`private`)
            try await ownPrivate.save(on: app.db)
            let ownLimited = DBGameSystem(name: "Gary Limited", createdByID: context.userID, visibility: .limited)
            try await ownLimited.save(on: app.db)
            let ownPublic = DBGameSystem(name: "Gary Public", createdByID: context.userID, visibility: .`public`)
            try await ownPublic.save(on: app.db)
            let othersPrivate = DBGameSystem(name: "Serena Private", createdByID: otherID, visibility: .`private`)
            try await othersPrivate.save(on: app.db)
            let othersLimited = DBGameSystem(name: "Serena Limited", createdByID: otherID, visibility: .limited)
            try await othersLimited.save(on: app.db)
            let othersPublic = DBGameSystem(name: "Serena Public", createdByID: otherID, visibility: .`public`)
            try await othersPublic.save(on: app.db)

            // Can edit own private (staying private)
            try await app.testing().test(.PATCH, "/v1/game-systems/\(try ownPrivate.requireID())", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: context.token)
                try req.content.encode(PatchDTO(name: "Gary Private Edit"))
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
                let dto = try res.content.decode(DTO.self)
                #expect(dto.name == "Gary Private Edit")
            })

            // Cannot edit own private to limited
            try await app.testing().test(.PATCH, "/v1/game-systems/\(try ownPrivate.requireID())", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: context.token)
                try req.content.encode(PatchDTO(visibility: .limited))
            }, afterResponse: { res async throws in
                #expect(res.status == .forbidden)
            })

            // Can edit own limited (staying limited)
            try await app.testing().test(.PATCH, "/v1/game-systems/\(try ownLimited.requireID())", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: context.token)
                try req.content.encode(PatchDTO(name: "Gary Limited Edit"))
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
                let dto = try res.content.decode(DTO.self)
                #expect(dto.name == "Gary Limited Edit")
            })

            // Cannot edit own limited to private
            try await app.testing().test(.PATCH, "/v1/game-systems/\(try ownLimited.requireID())", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: context.token)
                try req.content.encode(PatchDTO(visibility: .`private`))
            }, afterResponse: { res async throws in
                #expect(res.status == .forbidden)
            })

            // Can edit public item fields (no visibility change)
            try await app.testing().test(.PATCH, "/v1/game-systems/\(try othersPublic.requireID())", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: context.token)
                try req.content.encode(PatchDTO(name: "Serena Gary Public"))
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
                let dto = try res.content.decode(DTO.self)
                #expect(dto.name == "Serena Gary Public")
            })

            // Cannot downgrade public
            try await app.testing().test(.PATCH, "/v1/game-systems/\(try ownPublic.requireID())", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: context.token)
                try req.content.encode(PatchDTO(visibility: .`private`))
            }, afterResponse: { res async throws in
                #expect(res.status == .forbidden)
            })

            // Cannot edit others' private
            try await app.testing().test(.PATCH, "/v1/game-systems/\(try othersPrivate.requireID())", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: context.token)
                try req.content.encode(PatchDTO(name: "Serena Gary Private"))
            }, afterResponse: { res async throws in
                #expect(res.status == .notFound)
            })

            // Cannot edit others' limited
            try await app.testing().test(.PATCH, "/v1/game-systems/\(try othersLimited.requireID())", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: context.token)
                try req.content.encode(PatchDTO(name: "Serena Gary Limited"))
            }, afterResponse: { res async throws in
                #expect(res.status == .forbidden)
            })
        }
    }

    @Test("update game system as hobbyist")
    func updateHobbyist() async throws {
        try await AuthenticatedTestContext.run(
            migrations: MiniDexDB.migrations,
            username: "Clemont",
            roles: .hobbyist
        ) { context in
            let app = context.app
            try app.register(collection: GameSystemController())

            let other = try await AuthenticatedTestContext.createUser(
                on: app.db,
                username: "May",
                roles: .cataloguer
            )
            let otherID = try other.requireID()

            let ownPrivate = DBGameSystem(name: "Clemont Private", createdByID: context.userID, visibility: .`private`)
            try await ownPrivate.save(on: app.db)
            let ownLimited = DBGameSystem(name: "Clemont Limited", createdByID: context.userID, visibility: .limited)
            try await ownLimited.save(on: app.db)
            let ownPublic = DBGameSystem(name: "Clemont Public", createdByID: context.userID, visibility: .`public`)
            try await ownPublic.save(on: app.db)
            let othersPrivate = DBGameSystem(name: "May Private", createdByID: otherID, visibility: .`private`)
            try await othersPrivate.save(on: app.db)
            let othersLimited = DBGameSystem(name: "May Limited", createdByID: otherID, visibility: .limited)
            try await othersLimited.save(on: app.db)

            // Can edit own private (staying private)
            try await app.testing().test(.PATCH, "/v1/game-systems/\(try ownPrivate.requireID())", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: context.token)
                try req.content.encode(PatchDTO(name: "Clemont Private Edit"))
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
                let dto = try res.content.decode(DTO.self)
                #expect(dto.name == "Clemont Private Edit")
            })

            // Can edit own private -> limited
            try await app.testing().test(.PATCH, "/v1/game-systems/\(try ownPrivate.requireID())", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: context.token)
                try req.content.encode(PatchDTO(visibility: .limited))
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
                let dto = try res.content.decode(DTO.self)
                #expect(dto.visibility == .limited)
            })

            // Can edit own limited (staying limited)
            try await app.testing().test(.PATCH, "/v1/game-systems/\(try ownLimited.requireID())", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: context.token)
                try req.content.encode(PatchDTO(name: "Clemont Limited Edit"))
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
                let dto = try res.content.decode(DTO.self)
                #expect(dto.name == "Clemont Limited Edit")
            })

            // Can edit own limited -> private
            try await app.testing().test(.PATCH, "/v1/game-systems/\(try ownLimited.requireID())", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: context.token)
                try req.content.encode(PatchDTO(visibility: .`private`))
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
                let dto = try res.content.decode(DTO.self)
                #expect(dto.visibility == .`private`)
            })

            // Cannot promote to public
            try await app.testing().test(.PATCH, "/v1/game-systems/\(try ownLimited.requireID())", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: context.token)
                try req.content.encode(PatchDTO(visibility: .`public`))
            }, afterResponse: { res async throws in
                #expect(res.status == .forbidden)
            })

            // Cannot edit others' private
            try await app.testing().test(.PATCH, "/v1/game-systems/\(try othersPrivate.requireID())", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: context.token)
                try req.content.encode(PatchDTO(name: "May Clemont Private"))
            }, afterResponse: { res async throws in
                #expect(res.status == .notFound)
            })

            // Cannot edit others' limited
            try await app.testing().test(.PATCH, "/v1/game-systems/\(try othersLimited.requireID())", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: context.token)
                try req.content.encode(PatchDTO(name: "May Clemont Limited"))
            }, afterResponse: { res async throws in
                #expect(res.status == .notFound)
            })

            // Cannot edit public
            try await app.testing().test(.PATCH, "/v1/game-systems/\(try ownPublic.requireID())", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: context.token)
                try req.content.encode(PatchDTO(name: "Clemont Public Edit"))
            }, afterResponse: { res async throws in
                #expect(res.status == .forbidden)
            })
        }
    }

    @Test("delete game system as cataloguer")
    func deleteCataloguer() async throws {
        try await AuthenticatedTestContext.run(
            migrations: MiniDexDB.migrations,
            username: "ash",
            roles: .cataloguer
        ) { context in
            let app = context.app
            try app.register(collection: GameSystemController())

            let other = try await AuthenticatedTestContext.createUser(
                on: app.db,
                username: "oak",
                roles: .hobbyist
            )
            let otherID = try other.requireID()

            let ownPrivate = DBGameSystem(name: "Ash Private", createdByID: context.userID, visibility: .`private`)
            try await ownPrivate.save(on: app.db)
            let ownLimited = DBGameSystem(name: "Ash Limited", createdByID: context.userID, visibility: .limited)
            try await ownLimited.save(on: app.db)
            let othersPrivate = DBGameSystem(name: "Oak Private", createdByID: otherID, visibility: .`private`)
            try await othersPrivate.save(on: app.db)
            let othersLimited = DBGameSystem(name: "Oak Limited", createdByID: otherID, visibility: .limited)
            try await othersLimited.save(on: app.db)
            let othersPublic = DBGameSystem(name: "Oak Public", createdByID: otherID, visibility: .`public`)
            try await othersPublic.save(on: app.db)

            // Can delete own private
            try await app.testing().test(.DELETE, "/v1/game-systems/\(try ownPrivate.requireID())", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: context.token)
            }, afterResponse: { res async throws in
                #expect(res.status == .noContent)
            })

            // Can delete own limited
            try await app.testing().test(.DELETE, "/v1/game-systems/\(try ownLimited.requireID())", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: context.token)
            }, afterResponse: { res async throws in
                #expect(res.status == .noContent)
            })

            // Can delete public
            try await app.testing().test(.DELETE, "/v1/game-systems/\(try othersPublic.requireID())", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: context.token)
            }, afterResponse: { res async throws in
                #expect(res.status == .noContent)
            })

            // Cannot delete others' private
            try await app.testing().test(.DELETE, "/v1/game-systems/\(try othersPrivate.requireID())", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: context.token)
            }, afterResponse: { res async throws in
                #expect(res.status == .notFound)
            })

            // Cannot delete others' limited
            try await app.testing().test(.DELETE, "/v1/game-systems/\(try othersLimited.requireID())", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: context.token)
            }, afterResponse: { res async throws in
                #expect(res.status == .forbidden)
            })
        }
    }

    @Test("delete game system as hobbyist")
    func deleteHobbyist() async throws {
        try await AuthenticatedTestContext.run(
            migrations: MiniDexDB.migrations,
            username: "Cilan",
            roles: .hobbyist
        ) { context in
            let app = context.app
            try app.register(collection: GameSystemController())

            let other = try await AuthenticatedTestContext.createUser(
                on: app.db,
                username: "Lillie",
                roles: .cataloguer
            )
            let otherID = try other.requireID()

            let ownPrivate = DBGameSystem(name: "Cilan Private", createdByID: context.userID, visibility: .`private`)
            try await ownPrivate.save(on: app.db)
            let ownLimited = DBGameSystem(name: "Cilan Limited", createdByID: context.userID, visibility: .limited)
            try await ownLimited.save(on: app.db)
            let ownPublic = DBGameSystem(name: "Cilan Public", createdByID: context.userID, visibility: .`public`)
            try await ownPublic.save(on: app.db)
            let othersPrivate = DBGameSystem(name: "Lillie Private", createdByID: otherID, visibility: .`private`)
            try await othersPrivate.save(on: app.db)
            let othersLimited = DBGameSystem(name: "Lillie Limited", createdByID: otherID, visibility: .limited)
            try await othersLimited.save(on: app.db)

            // Can delete own private
            try await app.testing().test(.DELETE, "/v1/game-systems/\(try ownPrivate.requireID())", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: context.token)
            }, afterResponse: { res async throws in
                #expect(res.status == .noContent)
            })

            // Can delete own limited
            try await app.testing().test(.DELETE, "/v1/game-systems/\(try ownLimited.requireID())", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: context.token)
            }, afterResponse: { res async throws in
                #expect(res.status == .noContent)
            })

            // Cannot delete public
            try await app.testing().test(.DELETE, "/v1/game-systems/\(try ownPublic.requireID())", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: context.token)
            }, afterResponse: { res async throws in
                #expect(res.status == .forbidden)
            })

            // Cannot delete others' private
            try await app.testing().test(.DELETE, "/v1/game-systems/\(try othersPrivate.requireID())", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: context.token)
            }, afterResponse: { res async throws in
                #expect(res.status == .notFound)
            })

            // Cannot delete others' limited
            try await app.testing().test(.DELETE, "/v1/game-systems/\(try othersLimited.requireID())", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: context.token)
            }, afterResponse: { res async throws in
                #expect(res.status == .notFound)
            })
        }
    }

    @Test("pagination, sorting, and filtering work together")
    func combinedPaginationSortingFiltering() async throws {
        try await AuthenticatedTestContext.run(
            migrations: MiniDexDB.migrations,
            roles: .cataloguer
        ) { context in
            let app = context.app
            let userID = context.userID

            try app.register(collection: GameSystemController())

            // Create test data owned by authenticated user
            try await DBGameSystem(name: "Warhammer Alpha", createdByID: userID, visibility: .`public`).save(on: app.db)
            try await DBGameSystem(name: "Warhammer Beta", createdByID: userID, visibility: .`public`).save(on: app.db)
            try await DBGameSystem(name: "Warhammer Gamma", createdByID: userID, visibility: .`public`).save(on: app.db)
            try await DBGameSystem(name: "Warhammer Delta", createdByID: userID, visibility: .`public`).save(on: app.db)
            try await DBGameSystem(name: "Warhammer Epsilon", createdByID: userID, visibility: .`public`).save(on: app.db)
            try await DBGameSystem(name: "Dungeons & Dragons", createdByID: userID, visibility: .`public`).save(on: app.db)

            // filter by "Warhammer", sort by name descending, limit to 2, page 0
            try await app.testing().test(.GET, "/v1/game-systems?q=Warhammer&sort=name&order=desc&limit=2&page=0", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: context.token)
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
            try await app.testing().test(.GET, "/v1/game-systems?q=Warhammer&sort=name&order=desc&limit=3&page=1", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: context.token)
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
