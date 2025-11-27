@testable import AuthAPI
import AuthDB
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
        try await AuthenticatedTestContext.run(
            username: "may",
            roles: .admin,
        ) { context in
            let app = context.app
            try app.register(collection: UserController(rolesConverter: .test))

            try await app.testing().test(
                .PATCH,
                "v1/users/\(context.userID)",
                beforeRequest: { req in
                    req.headers.bearerAuthorization = .init(token: context.token)
                    try req.content.encode(PatchDTO())
                },
                afterResponse: { res async throws in
                    #expect(res.status == .ok)
                }
            )

            let tokens = try await DBUserToken.query(on: app.db)
                .filter(\.$user.$id == context.userID)
                .all()
            #expect(tokens.allSatisfy { !$0.isRevoked })

            try context.redis.assertAuthCacheSet(
                accessToken: context.token,
                userID: context.userID,
                ttl: context.expiresIn,
            )
        }
    }

    @Test("patch roles revokes and invalidates tokens")
    func patchRolesRevokesTokens() async throws {
        try await AuthenticatedTestContext.run(
            username: "dawn",
            roles: .admin,
        ) { context in
            let app = context.app
            try app.register(collection: UserController(rolesConverter: .test))

            try await app.testing().test(
                .PATCH,
                "v1/users/\(context.userID)",
                beforeRequest: { req in
                    req.headers.bearerAuthorization = .init(token: context.token)
                    try req.content.encode(PatchDTO(roles: [], isActive: nil))
                },
                afterResponse: { res async throws in
                    #expect(res.status == .ok)
                    let response = try res.content.decode(DTO.self)
                    #expect(response.roles.isEmpty)
                }
            )

            let tokens = try await DBUserToken.query(on: app.db)
                .filter(\.$user.$id == context.userID)
                .all()
            #expect(tokens.allSatisfy { $0.isRevoked })

            try context.redis.assertAuthCacheCleared(accessToken: context.token)
        }
    }

    @Test("patch isActive revokes and invalidates tokens")
    func patchActivityRevokesTokens() async throws {
        try await AuthenticatedTestContext.run(
            username: "paul",
            roles: .admin,
        ) { context in
            let app = context.app
            try app.register(collection: UserController(rolesConverter: .test))

            try await app.testing().test(
                .PATCH,
                "v1/users/\(context.userID)",
                beforeRequest: { req in
                    req.headers.bearerAuthorization = .init(token: context.token)
                    try req.content.encode(PatchDTO(roles: nil, isActive: false))
                },
                afterResponse: { res async throws in
                    #expect(res.status == .ok)
                    let response = try res.content.decode(DTO.self)
                    #expect(response.isActive == false)
                }
            )

            let tokens = try await DBUserToken.query(on: app.db)
                .filter(\.$user.$id == context.userID)
                .all()
            #expect(tokens.allSatisfy { $0.isRevoked })

            try context.redis.assertAuthCacheCleared(accessToken: context.token)
        }
    }

    @Test("patch roles to same value does not revoke tokens")
    func patchRolesToSameValueDoesNotRevokeTokens() async throws {
        try await AuthenticatedTestContext.run(
            username: "brock",
            roles: .admin,
        ) { context in
            let app = context.app
            try app.register(collection: UserController(rolesConverter: .test))

            try await app.testing().test(
                .PATCH,
                "v1/users/\(context.userID)",
                beforeRequest: { req in
                    req.headers.bearerAuthorization = .init(token: context.token)
                    try req.content.encode(PatchDTO(roles: ["admin"], isActive: nil))
                },
                afterResponse: { res async throws in
                    #expect(res.status == .ok)
                }
            )

            let tokens = try await DBUserToken.query(on: app.db)
                .filter(\.$user.$id == context.userID)
                .all()
            #expect(tokens.allSatisfy { !$0.isRevoked })

            try context.redis.assertAuthCacheSet(
                accessToken: context.token,
                userID: context.userID,
                ttl: context.expiresIn,
            )
        }
    }

    @Test("patch isActive to same value does not revoke tokens")
    func patchIsActiveToSameValueDoesNotRevokeTokens() async throws {
        try await AuthenticatedTestContext.run(
            username: "misty",
            roles: .admin,
        ) { context in
            let app = context.app
            try app.register(collection: UserController(rolesConverter: .test))

            try await app.testing().test(
                .PATCH,
                "v1/users/\(context.userID)",
                beforeRequest: { req in
                    req.headers.bearerAuthorization = .init(token: context.token)
                    try req.content.encode(PatchDTO(roles: nil, isActive: true))
                },
                afterResponse: { res async throws in
                    #expect(res.status == .ok)
                }
            )

            let tokens = try await DBUserToken.query(on: app.db)
                .filter(\.$user.$id == context.userID)
                .all()
            #expect(tokens.allSatisfy { !$0.isRevoked })

            try context.redis.assertAuthCacheSet(
                accessToken: context.token,
                userID: context.userID,
                ttl: context.expiresIn,
            )
        }
    }

    @Test("user cannot authenticate after role change")
    func userRejectedAfterRoleChange() async throws {
        try await AuthenticatedTestContext.run(
            username: "cynthia",
            password: "Password!23",
            roles: .admin,
        ) { context in
            let app = context.app
            try app.register(collection: UserController(rolesConverter: .test))

            try await app.testing().test(
                .POST,
                "v1/auth/logout",
                beforeRequest: { req in
                    req.headers.bearerAuthorization = .init(token: context.token)
                },
                afterResponse: { res async in
                    #expect(res.status == .ok)
                }
            )

            let login = try await AuthenticatedTestContext.login(
                app: app,
                username: "cynthia",
                password: "Password!23"
            )

            try await app.testing().test(
                .PATCH,
                "v1/users/\(context.userID)",
                beforeRequest: { req in
                    req.headers.bearerAuthorization = .init(token: login.accessToken)
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
                    req.headers.bearerAuthorization = .init(token: login.accessToken)
                },
                afterResponse: { res async in
                    #expect(res.status == .unauthorized)
                }
            )
        }
    }

    @Test("patch missing user returns not found")
    func patchMissingUser() async throws {
        try await AuthenticatedTestContext.run(
            username: "iris",
            roles: .admin,
        ) { context in
            let app = context.app
            try app.register(collection: UserController(rolesConverter: .test))

            try await app.testing().test(
                .PATCH,
                "v1/users/\(UUID().uuidString)",
                beforeRequest: { req in
                    req.headers.bearerAuthorization = .init(token: context.token)
                    try req.content.encode(PatchDTO())
                },
                afterResponse: { res async in
                    #expect(res.status == .notFound)
                }
            )
        }
    }

    @Test("invalidate sessions revokes tokens and clears cache")
    func invalidateSessions() async throws {
        try await AuthenticatedTestContext.run(
            username: "clemont",
            roles: .admin,
        ) { context in
            let app = context.app
            try app.register(collection: UserController(rolesConverter: .test))

            try await app.testing().test(
                .POST,
                "v1/users/\(context.userID)/invalidateSessions",
                beforeRequest: { req in
                    req.headers.bearerAuthorization = .init(token: context.token)
                },
                afterResponse: { res async in
                    #expect(res.status == .ok)
                }
            )

            let tokens = try await DBUserToken.query(on: app.db)
                .filter(\.$user.$id == context.userID)
                .all()
            #expect(tokens.allSatisfy { $0.isRevoked })

            try context.redis.assertAuthCacheCleared(accessToken: context.token)
        }
    }
}
