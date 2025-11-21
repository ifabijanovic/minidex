@testable import MiniDexServer
import Foundation
import Testing
import VaporTesting

@Suite("UserProfile Controller", .serialized)
struct UserProfileControllerTests {
    @Test("returns 404 when profile missing for user id")
    func getBeforeProfileCreation() async throws {
        try await TestContext.withAuthenticatedContext { context in
            try await context.app.testing().test(.GET, "/v1/users/\(context.userID)/profile", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: context.token)
            }, afterResponse: { res async throws in
                #expect(res.status == .notFound)
            })
        }
    }

    @Test("can create, fetch, and update profile via user route")
    func profileLifecycle() async throws {
        try await TestContext.withAuthenticatedContext { context in
            let app = context.app
            let token = context.token
            let userID = context.userID

            let initialAvatar = URL(string: "https://cdn.minidex.dev/avatars/initial.png")!
            var createdProfileID: UUID?

            try await app.testing().test(.POST, "/v1/users/\(userID)/profile", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: token)
                try req.content.encode(UserProfile(
                    id: nil,
                    userID: userID,
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
                try req.content.encode(UserProfilePatch(
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
}
