import Fluent
import MiniDexDB
@testable import MiniDexServer
import Foundation
import Testing
import VaporTesting
import VaporTestingUtils

@Suite("UserProfile admin Controller", .serialized)
struct UserProfileAdminControllerTests {
    typealias DTO = UserProfileAdminController.DTO
    typealias PostDTO = UserProfileAdminController.PostDTO
    typealias PatchDTO = UserProfileAdminController.PatchDTO

    @Test("returns 404 when profile missing for user id")
    func getBeforeProfileCreation() async throws {
        try await AuthenticatedTestContext.run(
            migrations: MiniDexDB.migrations,
            roles: .admin,
        ) { context in
            try context.app.register(collection: UserProfileAdminController())

            try await context.app.testing().test(
                .GET,
                "/v1/users/\(context.userID)/profile",
                beforeRequest: { req in
                    req.headers.bearerAuthorization = .init(token: context.token)
                }, afterResponse: { res async throws in
                    #expect(res.status == .notFound)
                }
            )
        }
    }

    @Test("can create, fetch, and update profile via user route")
    func profileLifecycle() async throws {
        try await AuthenticatedTestContext.run(
            migrations: MiniDexDB.migrations,
            roles: .admin,
        ) { context in
            let app = context.app
            let token = context.token
            let userID = context.userID

            try app.register(collection: UserProfileAdminController())

            let initialAvatar = URL(string: "https://cdn.minidex.dev/avatars/iris.png")!
            var createdProfileID: UUID?

            try await app.testing().test(
                .POST,
                "/v1/admin/users/\(userID)/profile",
                beforeRequest: { req in
                    req.headers.bearerAuthorization = .init(token: token)
                    try req.content.encode(PostDTO(
                        displayName: "Iris",
                        avatarURL: initialAvatar
                    ))
                }, afterResponse: { res async throws in
                    #expect(res.status == .ok)
                    let created = try res.content.decode(DTO.self)
                    createdProfileID = created.id
                    #expect(created.userID == userID)
                    #expect(created.displayName == "Iris")
                    #expect(created.avatarURL == initialAvatar)
                }
            )

            guard let profileID = createdProfileID else {
                Issue.record("Profile was not created")
                return
            }

            try await app.testing().test(
                .GET,
                "/v1/users/\(userID)/profile",
                beforeRequest: { req in
                    req.headers.bearerAuthorization = .init(token: token)
                }, afterResponse: { res async throws in
                    #expect(res.status == .ok)
                    let fetched = try res.content.decode(DTO.self)
                    #expect(fetched.id == profileID)
                    #expect(fetched.userID == userID)
                    #expect(fetched.avatarURL == initialAvatar)
                }
            )

            let updatedAvatar = URL(string: "https://cdn.minidex.dev/avatars/clemont.png")!

            try await app.testing().test(
                .PATCH,
                "/v1/admin/users/\(userID)/profile",
                beforeRequest: { req in
                    req.headers.bearerAuthorization = .init(token: token)
                    try req.content.encode(PatchDTO(
                        displayName: "Clemont",
                        avatarURL: updatedAvatar
                    ))
                }, afterResponse: { res async throws in
                    #expect(res.status == .ok)
                    let updated = try res.content.decode(DTO.self)
                    #expect(updated.displayName == "Clemont")
                    #expect(updated.avatarURL == updatedAvatar)
                }
            )

            // Ensure the nested route continues to resolve profiles by user id, not profile id.
            try await app.testing().test(
                .GET,
                "/v1/admin/users/\(profileID)/profile",
                beforeRequest: { req in
                    req.headers.bearerAuthorization = .init(token: token)
                }, afterResponse: { res async throws in
                    #expect(res.status == .notFound)
                }
            )
        }
    }

    @Test("non-admin can fetch another user's profile")
    func nonAdminCanAccessAnotherUsersProfile() async throws {
        try await AuthenticatedTestContext.run(
            migrations: MiniDexDB.migrations,
            username: "ash",
            roles: .hobbyist
        ) { context in
            let app = context.app
            try app.register(collection: UserProfileAdminController())

            let targetUser = try await AuthenticatedTestContext.createUser(
                on: app.db,
                username: "misty",
                roles: .hobbyist
            )
            let targetUserID = try targetUser.requireID()
            try await seedProfile(on: app, userID: targetUserID, displayName: "Misty")

            try await app.testing().test(
                .GET,
                "/v1/users/\(targetUserID)/profile",
                beforeRequest: { req in
                    req.headers.bearerAuthorization = .init(token: context.token)
                }, afterResponse: { res async throws in
                    #expect(res.status == .ok)
                    let fetched = try res.content.decode(DTO.self)
                    #expect(fetched.userID == targetUserID)
                    #expect(fetched.displayName == "Misty")
                }
            )
        }
    }

    @Test("non-admin cannot create profile via admin route")
    func nonAdminCannotPostOwnProfile() async throws {
        try await AuthenticatedTestContext.run(
            migrations: MiniDexDB.migrations,
            username: "brock",
            roles: .hobbyist
        ) { context in
            let app = context.app
            try app.register(collection: UserProfileAdminController())

            try await app.testing().test(
                .POST,
                "/v1/admin/users/\(context.userID)/profile",
                beforeRequest: { req in
                    req.headers.bearerAuthorization = .init(token: context.token)
                    try req.content.encode(PostDTO(
                        displayName: "Brock",
                        avatarURL: URL(string: "https://cdn.minidex.dev/avatars/brock.png")
                    ))
                }, afterResponse: { res async throws in
                    #expect(res.status == .forbidden)
                }
            )
        }
    }

    @Test("non-admin cannot update profile via admin route")
    func nonAdminCannotPatchOwnProfile() async throws {
        try await AuthenticatedTestContext.run(
            migrations: MiniDexDB.migrations,
            username: "may",
            roles: .hobbyist
        ) { context in
            let app = context.app
            try app.register(collection: UserProfileAdminController())
            let userID = context.userID

            try await seedProfile(on: app, userID: userID, displayName: "May")

            try await app.testing().test(
                .PATCH,
                "/v1/admin/users/\(userID)/profile",
                beforeRequest: { req in
                    req.headers.bearerAuthorization = .init(token: context.token)
                    try req.content.encode(PatchDTO(
                        displayName: "Updated May",
                        avatarURL: URL(string: "https://cdn.minidex.dev/avatars/may.png")
                    ))
                }, afterResponse: { res async throws in
                    #expect(res.status == .forbidden)
                }
            )
        }
    }

    private func seedProfile(on app: Application, userID: UUID, displayName: String) async throws {
        let profile = DBUserProfile(
            userID: userID,
            displayName: displayName,
            avatarURL: nil
        )
        try await profile.save(on: app.db)
    }
}
