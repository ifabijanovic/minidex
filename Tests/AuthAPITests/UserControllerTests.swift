@testable import AuthAPI
@testable import AuthDB
import Fluent
import Testing
import Vapor
import VaporTesting
import VaporTestingUtils
import VaporRedisUtils
@preconcurrency import Redis

@Suite("UserController", .serialized)
struct UserControllerTests {
    typealias DTO = UserController.DTO
    typealias PostDTO = UserController.PostDTO
    typealias PatchDTO = UserController.PatchDTO

    @Test("patching nothing does not revoke tokens")
    func patchingNothingDoesNotRevokeTokens() async throws {
        try await AuthAPITestApp.withApp { app, redis in
            let (_, adminToken) = try await makeAdmin(app: app)
            let target = try await AuthenticatedTestContext.createUser(
                on: app.db,
                username: "may",
                roles: .admin,
                isActive: true
            )
            let targetID = try target.requireID()
            _ = try await AuthenticatedTestContext.login(
                app: app,
                username: "may",
                password: "Password!23"
            )

            try await app.testing().test(
                .PATCH,
                "v1/users/\(targetID)",
                beforeRequest: { req in
                    AuthAPITestHelpers.authorize(&req, token: adminToken.accessToken)
                    try req.content.encode(PatchDTO())
                },
                afterResponse: { res async throws in
                    #expect(res.status == .ok)
                }
            )

            let tokens = try await DBUserToken.query(on: app.db)
                .filter(\.$user.$id == targetID)
                .all()
            #expect(tokens.allSatisfy { !$0.isRevoked })

            #expect(redis.snapshot().deleteCalls.isEmpty)
        }
    }

    @Test("patch roles revokes and invalidates tokens")
    func patchRolesRevokesTokens() async throws {
        try await AuthAPITestApp.withApp { app, redis in
            let (_, adminToken) = try await makeAdmin(app: app)
            let target = try await AuthenticatedTestContext.createUser(
                on: app.db,
                username: "dawn",
                roles: .admin,
                isActive: true
            )
            let targetID = try target.requireID()

            let targetLogin = try await AuthenticatedTestContext.login(
                app: app,
                username: "dawn",
                password: "Password!23"
            )

            try await app.testing().test(
                .PATCH,
                "v1/users/\(targetID)",
                beforeRequest: { req in
                    AuthAPITestHelpers.authorize(&req, token: adminToken.accessToken)
                    try req.content.encode(PatchDTO(roles: [], isActive: nil))
                },
                afterResponse: { res async throws in
                    #expect(res.status == .ok)
                    let response = try res.content.decode(DTO.self)
                    #expect(response.roles.isEmpty)
                }
            )

            let tokens = try await DBUserToken.query(on: app.db)
                .filter(\.$user.$id == targetID)
                .all()
            #expect(tokens.allSatisfy { $0.isRevoked })

            try AuthAPITestHelpers.assertCacheCleared(for: targetLogin, redis: redis)
        }
    }

    @Test("patch isActive revokes and invalidates tokens")
    func patchActivityRevokesTokens() async throws {
        try await AuthAPITestApp.withApp { app, redis in
            let (_, adminToken) = try await makeAdmin(app: app)
            let target = try await AuthenticatedTestContext.createUser(
                on: app.db,
                username: "paul",
                roles: .admin,
                isActive: true
            )
            let targetID = try target.requireID()
            let targetLogin = try await AuthenticatedTestContext.login(
                app: app,
                username: "paul",
                password: "Password!23"
            )

            try await app.testing().test(
                .PATCH,
                "v1/users/\(targetID)",
                beforeRequest: { req in
                    AuthAPITestHelpers.authorize(&req, token: adminToken.accessToken)
                    try req.content.encode(PatchDTO(roles: nil, isActive: false))
                },
                afterResponse: { res async throws in
                    #expect(res.status == .ok)
                    let response = try res.content.decode(DTO.self)
                    #expect(response.isActive == false)
                }
            )

            let tokens = try await DBUserToken.query(on: app.db)
                .filter(\.$user.$id == targetID)
                .all()
            #expect(tokens.allSatisfy { $0.isRevoked })

            try AuthAPITestHelpers.assertCacheCleared(for: targetLogin, redis: redis)
        }
    }

    @Test("patch roles to same value does not revoke tokens")
    func patchRolesToSameValueDoesNotRevokeTokens() async throws {
        try await AuthAPITestApp.withApp { app, redis in
            let (_, adminToken) = try await makeAdmin(app: app)
            let target = try await AuthenticatedTestContext.createUser(
                on: app.db,
                username: "brock",
                roles: .admin,
                isActive: true
            )
            let targetID = try target.requireID()
            let targetLogin = try await AuthenticatedTestContext.login(
                app: app,
                username: "brock",
                password: "Password!23"
            )

            try await app.testing().test(
                .PATCH,
                "v1/users/\(targetID)",
                beforeRequest: { req in
                    AuthAPITestHelpers.authorize(&req, token: adminToken.accessToken)
                    try req.content.encode(PatchDTO(roles: .admin, isActive: nil))
                },
                afterResponse: { res async throws in
                    #expect(res.status == .ok)
                }
            )

            let tokens = try await DBUserToken.query(on: app.db)
                .filter(\.$user.$id == targetID)
                .all()
            #expect(tokens.allSatisfy { !$0.isRevoked })

            try await app.testing().test(
                .POST,
                "v1/auth/logout",
                beforeRequest: { req in
                    AuthAPITestHelpers.authorize(&req, token: targetLogin.accessToken)
                },
                afterResponse: { res async in
                    #expect(res.status == .ok)
                }
            )
        }
    }

    @Test("patch isActive to same value does not revoke tokens")
    func patchIsActiveToSameValueDoesNotRevokeTokens() async throws {
        try await AuthAPITestApp.withApp { app, redis in
            let (_, adminToken) = try await makeAdmin(app: app)
            let target = try await AuthenticatedTestContext.createUser(
                on: app.db,
                username: "misty",
                roles: .admin,
                isActive: true
            )
            let targetID = try target.requireID()
            let targetLogin = try await AuthenticatedTestContext.login(
                app: app,
                username: "misty",
                password: "Password!23"
            )

            try await app.testing().test(
                .PATCH,
                "v1/users/\(targetID)",
                beforeRequest: { req in
                    AuthAPITestHelpers.authorize(&req, token: adminToken.accessToken)
                    try req.content.encode(PatchDTO(roles: nil, isActive: true))
                },
                afterResponse: { res async throws in
                    #expect(res.status == .ok)
                }
            )

            let tokens = try await DBUserToken.query(on: app.db)
                .filter(\.$user.$id == targetID)
                .all()
            #expect(tokens.allSatisfy { !$0.isRevoked })

            try await app.testing().test(
                .POST,
                "v1/auth/logout",
                beforeRequest: { req in
                    AuthAPITestHelpers.authorize(&req, token: targetLogin.accessToken)
                },
                afterResponse: { res async in
                    #expect(res.status == .ok)
                }
            )
        }
    }

    @Test("user cannot authenticate after role change")
    func userRejectedAfterRoleChange() async throws {
        try await AuthAPITestApp.withApp { app, redis in
            let (_, adminToken) = try await makeAdmin(app: app)
            let target = try await AuthenticatedTestContext.createUser(
                on: app.db,
                username: "cynthia",
                roles: .admin,
                isActive: true
            )
            let targetID = try target.requireID()
            let targetLogin = try await AuthenticatedTestContext.login(app: app, username: "cynthia", password: "Password!23")

            try await app.testing().test(
                .POST,
                "v1/auth/logout",
                beforeRequest: { req in
                    AuthAPITestHelpers.authorize(&req, token: targetLogin.accessToken)
                },
                afterResponse: { res async in
                    #expect(res.status == .ok)
                }
            )

            let targetLogin2 = try await AuthenticatedTestContext.login(
                app: app,
                username: "cynthia",
                password: "Password!23"
            )

            try await app.testing().test(
                .PATCH,
                "v1/users/\(targetID)",
                beforeRequest: { req in
                    AuthAPITestHelpers.authorize(&req, token: adminToken.accessToken)
                    try req.content.encode(PatchDTO(roles: [], isActive: nil))
                },
                afterResponse: { res async throws in
                    #expect(res.status == .ok)
                }
            )

            try await app.testing().test(
                .POST,
                "v1/auth/logout",
                beforeRequest: { req in
                    AuthAPITestHelpers.authorize(&req, token: targetLogin2.accessToken)
                },
                afterResponse: { res async in
                    #expect(res.status == .unauthorized)
                }
            )
        }
    }

    @Test("patch missing user returns not found")
    func patchMissingUser() async throws {
        try await AuthAPITestApp.withApp { app, _ in
            let (_, adminToken) = try await makeAdmin(app: app)

            try await app.testing().test(
                .PATCH,
                "v1/users/\(UUID().uuidString)",
                beforeRequest: { req in
                    AuthAPITestHelpers.authorize(&req, token: adminToken.accessToken)
                    try req.content.encode(PatchDTO())
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
            let target = try await AuthenticatedTestContext.createUser(
                on: app.db,
                username: "lyra",
                roles: .admin,
                isActive: true
            )
            let targetID = try target.requireID()
            let targetLogin = try await AuthenticatedTestContext.login(
                app: app,
                username: "lyra",
                password: "Password!23"
            )

            try await app.testing().test(
                .POST,
                "v1/users/\(targetID)/revokeAccess",
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
            #expect(tokens.allSatisfy { $0.isRevoked })

            try AuthAPITestHelpers.assertCacheCleared(for: targetLogin, redis: redis)
        }
    }
}

private func makeAdmin(app: Application) async throws -> (DBUser, TestLoginResponse) {
    let admin = try await AuthenticatedTestContext.createUser(
        on: app.db,
        username: "admin",
        password: "AdminPassword!23",
        roles: .admin,
        isActive: true
    )
    let login = try await AuthenticatedTestContext.login(app: app, username: "admin", password: "AdminPassword!23")
    return (admin, login)
}
