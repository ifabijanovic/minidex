import Vapor

public struct RequireAdminMiddleware: AsyncMiddleware {
    public init() {}

    public func respond(to request: Request, chainingTo next: any AsyncResponder) async throws -> Response {
        return try await AuthAPI.respond(to: request, chainingTo: next) { $0.contains(.admin) }
    }
}

public struct RequireAllRolesMiddleware: AsyncMiddleware {
    let roles: Roles

    public init(roles: Roles) {
        self.roles = roles
    }

    public func respond(to request: Request, chainingTo next: any AsyncResponder) async throws -> Response {
        return try await AuthAPI.respond(to: request, chainingTo: next) { $0.contains(roles) }
    }
}

public struct RequireAnyRolesMiddleware: AsyncMiddleware {
    let roles: Roles

    public init(roles: Roles) {
        self.roles = roles
    }

    public func respond(to request: Request, chainingTo next: any AsyncResponder) async throws -> Response {
        return try await AuthAPI.respond(to: request, chainingTo: next) { !$0.intersection(roles).isEmpty }
    }
}

private func respond(
    to request: Request,
    chainingTo next: any AsyncResponder,
    match: @Sendable @escaping (Roles) -> Bool,
) async throws -> Response {
    guard let user = request.auth.get(User.self), match(user.roles) else {
        throw Abort(.forbidden)
    }
    return try await next.respond(to: request)
}
