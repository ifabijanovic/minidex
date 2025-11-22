import Fluent
import MiniDexDB
@testable import MiniDexServer
import Testing
import VaporTesting
import VaporTestingUtils

@Suite("Me Controller", .serialized)
struct MeControllerTests {
    typealias DTO = MeController.DTO
    typealias PostDTO = MeController.PostDTO
    typealias PatchDTO = MeController.PatchDTO

    @Test("user can fetch their own profile")
    func fetchOwnProfile() async throws {
        try await AuthenticatedTestContext.run(
            migrations: MiniDexDB.migrations,
            username: "ash",
            roles: .hobbyist
        ) { context in
            let app = context.app
            try app.register(collection: MeController())

            let avatar = URL(string: "https://cdn.minidex.dev/avatars/ash.png")!
            try await seedProfile(on: app, userID: context.userID, displayName: "Ash", avatarURL: avatar)

            try await app.testing().test(.GET, "/v1/me", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: context.token)
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
                let dto = try res.content.decode(DTO.self)
                #expect(dto.userID == context.userID)
                #expect(dto.displayName == "Ash")
                #expect(dto.avatarURL == avatar)
            })
        }
    }

    @Test("user can create their own profile")
    func createOwnProfile() async throws {
        try await AuthenticatedTestContext.run(
            migrations: MiniDexDB.migrations,
            username: "misty",
            roles: .hobbyist
        ) { context in
            let app = context.app
            try app.register(collection: MeController())

            let avatar = URL(string: "https://cdn.minidex.dev/avatars/misty.png")!

            try await app.testing().test(.POST, "/v1/me", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: context.token)
                try req.content.encode(PostDTO(
                    displayName: "Misty",
                    avatarURL: avatar
                ))
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
                let dto = try res.content.decode(DTO.self)
                #expect(dto.userID == context.userID)
                #expect(dto.displayName == "Misty")
                #expect(dto.avatarURL == avatar)
            })
        }
    }

    @Test("user can update their own profile")
    func updateOwnProfile() async throws {
        try await AuthenticatedTestContext.run(
            migrations: MiniDexDB.migrations,
            username: "brock",
            roles: .hobbyist
        ) { context in
            let app = context.app
            try app.register(collection: MeController())

            try await seedProfile(on: app, userID: context.userID, displayName: "Brock", avatarURL: nil)

            let updatedAvatar = URL(string: "https://cdn.minidex.dev/avatars/brock.png")!

            try await app.testing().test(.PATCH, "/v1/me", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: context.token)
                try req.content.encode(PatchDTO(
                    displayName: "Updated Brock",
                    avatarURL: updatedAvatar
                ))
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
                let dto = try res.content.decode(DTO.self)
                #expect(dto.userID == context.userID)
                #expect(dto.displayName == "Updated Brock")
                #expect(dto.avatarURL == updatedAvatar)
            })
        }
    }

    private func seedProfile(
        on app: Application,
        userID: UUID,
        displayName: String,
        avatarURL: URL?
    ) async throws {
        let profile = DBUserProfile(
            userID: userID,
            displayName: displayName,
            avatarURL: avatarURL?.absoluteString
        )
        try await profile.save(on: app.db)
    }
}
