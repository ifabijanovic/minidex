@testable import AuthAPI
import Vapor
import Testing

@Suite("RolesMiddleware", .serialized)
struct RolesMiddlewareTests {
    @Test("RequireAdmin allows admins")
    func requireAdminAllowsAdmin() async throws {
        let middleware = RequireAdminMiddleware()
        try await withRequest(userRoles: [.admin]) { req, responder in
            let response = try await middleware.respond(to: req, chainingTo: responder)
            #expect(response.status == .ok)
        }
    }

    @Test("RequireAdmin denies missing admin role")
    func requireAdminDeniesNonAdmin() async throws {
        let middleware = RequireAdminMiddleware()
        try await withRequest(userRoles: []) { req, responder in
            await #expect(throws: Abort.self) {
                _ = try await middleware.respond(to: req, chainingTo: responder)
            }
        }
    }

    @Test("RequireAllRoles enforces full set")
    func requireAllRoles() async throws {
        let targetRoles: Roles = [.admin, Roles(rawValue: 1 << 2)]
        let middleware = RequireAllRolesMiddleware(roles: targetRoles)
        try await withRequest(userRoles: targetRoles) { req, responder in
            let response = try await middleware.respond(to: req, chainingTo: responder)
            #expect(response.status == .ok)
        }

        try await withRequest(userRoles: [.admin]) { req, responder in
            await #expect(throws: Abort.self) {
                _ = try await middleware.respond(to: req, chainingTo: responder)
            }
        }
    }

    @Test("RequireAnyRoles allows intersection")
    func requireAnyRoles() async throws {
        let middleware = RequireAnyRolesMiddleware(roles: [.admin, Roles(rawValue: 1 << 2)])
        try await withRequest(userRoles: [.admin]) { req, responder in
            let response = try await middleware.respond(to: req, chainingTo: responder)
            #expect(response.status == .ok)
        }

        try await withRequest(userRoles: []) { req, responder in
            await #expect(throws: Abort.self) {
                _ = try await middleware.respond(to: req, chainingTo: responder)
            }
        }
    }
}

// MARK: - Helpers

private func withRequest(
    userRoles: Roles,
    _ body: @escaping (Request, TestResponder) async throws -> Void
) async throws {
    let app = try await Application.make(.testing)

    let req = Request(application: app, on: app.eventLoopGroup.next())
    if !userRoles.isEmpty {
        let user = AuthUser(id: UUID(), roles: userRoles, isActive: true, tokenID: nil)
        req.auth.login(user)
    }
    let responder = TestResponder()
    do {
        try await body(req, responder)
    } catch {
        try await app.asyncShutdown()
        throw error
    }
    try await app.asyncShutdown()
}

private struct TestResponder: AsyncResponder {
    func respond(to request: Request) async throws -> Response {
        Response(status: .ok)
    }
}
