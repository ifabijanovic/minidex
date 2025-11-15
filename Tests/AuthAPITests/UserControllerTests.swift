@testable import AuthAPI
@testable import AuthDB
import Fluent
import Testing
import Vapor
import VaporTesting
import VaporRedisUtils
@preconcurrency import Redis

@Suite("UserController", .serialized)
struct UserControllerTests {
    @Test("patch display name does not invalidate cache")
    func patchDisplayNameIgnoresCache() async throws {
        try await AuthAPITestApp.withApp { app, redis in
            let (_, adminToken) = try await makeAdmin(app: app)
            let target = try await AuthAPITestHelpers.createUser(
                on: app.db,
                username: "may",
                roles: [],
                isActive: true
            )
            let targetID = try target.requireID()

            try await app.testing().test(
                .PATCH,
                "api/user/\(targetID)",
                beforeRequest: { req in
                    AuthAPITestHelpers.authorize(&req, token: adminToken.accessToken)
                    try req.content.encode(UserPatchIn(displayName: "Updated", roles: nil, isActive: nil))
                },
                afterResponse: { res async throws in
                    #expect(res.status == .ok)
                    let response = try res.content.decode(User.self)
                    #expect(response.displayName == "Updated")
                }
            )

            #expect(redis.snapshot().deleteCalls.isEmpty)
        }
    }

    @Test("patch roles invalidates cached tokens")
    func patchRolesInvalidatesCache() async throws {
        try await AuthAPITestApp.withApp { app, redis in
            let (_, adminToken) = try await makeAdmin(app: app)
            let target = try await AuthAPITestHelpers.createUser(
                on: app.db,
                username: "dawn",
                roles: [.admin],
                isActive: true
            )
            let targetID = try target.requireID()

            let targetLogin = try await AuthAPITestHelpers.login(app: app, username: "dawn", password: "Password!23")

            try await app.testing().test(
                .PATCH,
                "api/user/\(targetID)",
                beforeRequest: { req in
                    AuthAPITestHelpers.authorize(&req, token: adminToken.accessToken)
                    try req.content.encode(UserPatchIn(displayName: nil, roles: [], isActive: nil))
                },
                afterResponse: { res async throws in
                    #expect(res.status == .ok)
                    let response = try res.content.decode(User.self)
                    #expect(response.roles.isEmpty)
                }
            )

            try AuthAPITestHelpers.assertCacheCleared(for: targetLogin, redis: redis)
        }
    }

    @Test("patch isActive invalidates cached tokens")
    func patchActivityInvalidatesCache() async throws {
        try await AuthAPITestApp.withApp { app, redis in
            let (_, adminToken) = try await makeAdmin(app: app)
            let target = try await AuthAPITestHelpers.createUser(
                on: app.db,
                username: "paul",
                roles: [.admin],
                isActive: true
            )
            let targetID = try target.requireID()
            let targetLogin = try await AuthAPITestHelpers.login(app: app, username: "paul", password: "Password!23")

            try await app.testing().test(
                .PATCH,
                "api/user/\(targetID)",
                beforeRequest: { req in
                    AuthAPITestHelpers.authorize(&req, token: adminToken.accessToken)
                    try req.content.encode(UserPatchIn(displayName: nil, roles: nil, isActive: false))
                },
                afterResponse: { res async throws in
                    #expect(res.status == .ok)
                    let response = try res.content.decode(User.self)
                    #expect(response.isActive == false)
                }
            )

            try AuthAPITestHelpers.assertCacheCleared(for: targetLogin, redis: redis)
        }
    }

    @Test("patch missing user returns not found")
    func patchMissingUser() async throws {
        try await AuthAPITestApp.withApp { app, _ in
            let (_, adminToken) = try await makeAdmin(app: app)

            try await app.testing().test(
                .PATCH,
                "api/user/\(UUID().uuidString)",
                beforeRequest: { req in
                    AuthAPITestHelpers.authorize(&req, token: adminToken.accessToken)
                    try req.content.encode(UserPatchIn(displayName: "noop", roles: nil, isActive: nil))
                },
                afterResponse: { res async in
                    #expect(res.status == .notFound)
                }
            )
        }
    }

    @Test("revoke access revokes tokens and clears cache")
    func revokeAccess() async throws {
        try await AuthAPITestApp.withApp { app, redis in
            let (_, adminToken) = try await makeAdmin(app: app)
            let target = try await AuthAPITestHelpers.createUser(
                on: app.db,
                username: "lyra",
                roles: [.admin],
                isActive: true
            )
            let targetID = try target.requireID()
            let targetLogin = try await AuthAPITestHelpers.login(app: app, username: "lyra", password: "Password!23")

            try await app.testing().test(
                .POST,
                "api/user/\(targetID)/revokeAccess",
                beforeRequest: { req in
                    AuthAPITestHelpers.authorize(&req, token: adminToken.accessToken)
                },
                afterResponse: { res async in
                    #expect(res.status == .ok)
                }
            )

            let tokens = try await DBUserToken.query(on: app.db)
                .filter(\.$user.$id == targetID)
                .all()
            let allRevoked = tokens.allSatisfy(\.isRevoked)
            #expect(allRevoked)

            try AuthAPITestHelpers.assertCacheCleared(for: targetLogin, redis: redis)
        }
    }
}

private func makeAdmin(app: Application) async throws -> (DBUser, LoginResponse) {
    let admin = try await AuthAPITestHelpers.createUser(
        on: app.db,
        username: "admin",
        password: "AdminPassword!23",
        roles: [.admin],
        isActive: true
    )
    let login = try await AuthAPITestHelpers.login(app: app, username: "admin", password: "AdminPassword!23")
    return (admin, login)
}
