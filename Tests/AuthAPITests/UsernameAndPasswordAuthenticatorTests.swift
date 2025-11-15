@testable import AuthAPI
@testable import AuthDB
import Fluent
import Testing
import Vapor
import VaporTesting

@Suite("UsernameAndPasswordAuthenticator", .serialized)
struct UsernameAndPasswordAuthenticatorTests {
    private let authenticator = UsernameAndPasswordAuthenticator()

    @Test("authenticates valid credentials")
    func authenticatesValidCredential() async throws {
        try await withApp { app in
            _ = try await AuthAPITestHelpers.createUser(on: app.db, username: "ash", password: "pikachu", roles: [.admin])

            let req = makeRequest(app: app)
            let basic = BasicAuthorization(username: "ash", password: "pikachu")
            try await authenticator.authenticate(basic: basic, for: req)

            let authed = try req.auth.require(AuthUser.self)
            #expect(authed.roles.contains(.admin))
        }
    }

    @Test("fails when credential missing")
    func failsWhenCredentialMissing() async throws {
        try await withApp { app in
            let req = makeRequest(app: app)
            let basic = BasicAuthorization(username: "missing", password: "anything")
            try await authenticator.authenticate(basic: basic, for: req)
            #expect(req.auth.has(AuthUser.self) == false)
        }
    }

    @Test("fails when password incorrect")
    func failsWhenPasswordIncorrect() async throws {
        try await withApp { app in
            _ = try await AuthAPITestHelpers.createUser(on: app.db, username: "misty", password: "staryu", roles: [.admin])

            let req = makeRequest(app: app)
            let basic = BasicAuthorization(username: "misty", password: "wrong")
            try await authenticator.authenticate(basic: basic, for: req)
            #expect(req.auth.has(AuthUser.self) == false)
        }
    }
}

private func withApp(_ test: @escaping (Application) async throws -> Void) async throws {
    let app = try await Application.make(.testing)
    try await TestDatabaseHelpers.migrate(app)
    do {
        try await test(app)
    } catch {
        try await TestDatabaseHelpers.reset(app)
        try await app.asyncShutdown()
        throw error
    }
    try await TestDatabaseHelpers.reset(app)
    try await app.asyncShutdown()
}

private func makeRequest(app: Application) -> Request {
    Request(application: app, on: app.eventLoopGroup.next())
}
