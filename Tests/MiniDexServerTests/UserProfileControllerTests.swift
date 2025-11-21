import Fluent
import MiniDexDB
@testable import MiniDexServer
import Foundation
import Testing
import VaporTesting
import VaporTestingUtils

@Suite("UserProfile Controller", .serialized)
struct UserProfileControllerTests {
    @Test("returns 404 when profile missing for user id")
    func getBeforeProfileCreation() async throws {
        try await AuthenticatedTestContext.run(
            migrations: MiniDexDB.migrations,
            roles: .admin,
        ) { context in
            try context.app.register(collection: UserProfileController())

            try await context.app.testing().test(.GET, "/v1/users/\(context.userID)/profile", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: context.token)
            }, afterResponse: { res async throws in
                #expect(res.status == .notFound)
            })
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

            try app.register(collection: UserProfileController())

            let initialAvatar = URL(string: "https://cdn.minidex.dev/avatars/initial.png")!
            var createdProfileID: UUID?

            try await app.testing().test(.POST, "/v1/users/\(userID)/profile", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: token)
                try req.content.encode(UserProfilePostIn(
                    displayName: "Cataloguer",
                    avatarURL: initialAvatar
                ))
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
                let created = try res.content.decode(UserProfile.self)
                createdProfileID = created.id
                #expect(created.userID == userID)
                #expect(created.avatarURL == initialAvatar)
            })

            guard let profileID = createdProfileID else {
                Issue.record("Profile was not created")
                return
            }

            try await app.testing().test(.GET, "/v1/users/\(userID)/profile", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: token)
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
                let fetched = try res.content.decode(UserProfile.self)
                #expect(fetched.id == profileID)
                #expect(fetched.userID == userID)
                #expect(fetched.avatarURL == initialAvatar)
            })

            let updatedAvatar = URL(string: "https://cdn.minidex.dev/avatars/updated.png")!

            try await app.testing().test(.PATCH, "/v1/users/\(userID)/profile", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: token)
                try req.content.encode(UserProfilePatchIn(
                    displayName: "Updated Cataloguer",
                    avatarURL: updatedAvatar
                ))
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
                let updated = try res.content.decode(UserProfile.self)
                #expect(updated.displayName == "Updated Cataloguer")
                #expect(updated.avatarURL == updatedAvatar)
            })

            // Ensure the nested route continues to resolve profiles by user id, not profile id.
            try await app.testing().test(.GET, "/v1/users/\(profileID)/profile", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: token)
            }, afterResponse: { res async throws in
                #expect(res.status == .notFound)
            })
        }
    }

    @Test("user can fetch another user's profile")
    func userCanAccessAnotherUsersProfile() async throws {
        try await AuthenticatedTestContext.run(
            migrations: MiniDexDB.migrations,
            username: "ash",
            roles: .hobbyist
        ) { context in
            let app = context.app
            try app.register(collection: UserProfileController())

            let targetUser = try await AuthenticatedTestContext.createUser(
                on: app.db,
                username: "misty",
                roles: .hobbyist
            )
            let targetUserID = try targetUser.requireID()
            try await seedProfile(on: app, userID: targetUserID, displayName: "Misty")

            try await app.testing().test(.GET, "/v1/users/\(targetUserID)/profile", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: context.token)
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
                let fetched = try res.content.decode(UserProfile.self)
                #expect(fetched.userID == targetUserID)
                #expect(fetched.displayName == "Misty")
            })
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
