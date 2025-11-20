@testable import MiniDexServer
import AuthAPI
import AuthDB
import Fluent
import FluentSQLiteDriver
import MiniDexDB
import Vapor
import VaporRedisUtils
import VaporUtils
import VaporTesting
import Testing

@Suite("GameSystem Integration", .serialized)
struct GameSystemIntegrationTests {
    @Test("cataloguer can CRUD game systems via API")
    func cataloguerCRUD() async throws {
        let app = try await Application.makeTesting()
        let redisDriver = InMemoryRedisDriver()
        do {
            app.useRedisClientOverride { request in
                redisDriver.makeClient(on: request.eventLoop)
            }
            app.databases.use(.sqlite(.memory), as: .sqlite)
            app.migrations.add(AuthDB.migrations)
            app.migrations.add(MiniDexDB.migrations)
            try await app.autoMigrate()
            try routes(app)

            let cataloguer = try await createCataloguer(on: app.db)
            let login = try await loginCataloguer(app: app, username: cataloguer.username, password: cataloguer.password)
            let token = login.accessToken

            var createdID: UUID?

            try await app.testing().test(.POST, "/v1/gamesystem", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: token)
                try req.content.encode(GameSystem(id: nil, name: "Warhammer"))
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
                let dto = try res.content.decode(GameSystem.self)
                createdID = dto.id
                #expect(dto.name == "Warhammer")
            })

            guard let id = createdID else {
                Issue.record("Game system not created")
                return
            }

            try await app.testing().test(.GET, "/v1/gamesystem", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: token)
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
                let list = try res.content.decode([GameSystem].self)
                #expect(list.contains(where: { $0.id == id }))
            })

            try await app.testing().test(.PATCH, "/v1/gamesystem/\(id)", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: token)
                try req.content.encode(["name": "Warhammer 40k"])
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
            })

            try await app.testing().test(.GET, "/v1/gamesystem/\(id)", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: token)
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
                let dto = try res.content.decode(GameSystem.self)
                #expect(dto.name == "Warhammer 40k")
            })

            try await app.testing().test(.DELETE, "/v1/gamesystem/\(id)", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: token)
            }, afterResponse: { res async throws in
                #expect(res.status == .noContent)
            })

            try await app.testing().test(.GET, "/v1/gamesystem", beforeRequest: { req in
                req.headers.bearerAuthorization = .init(token: token)
            }, afterResponse: { res async throws in
                let list = try res.content.decode([GameSystem].self)
                #expect(list.contains(where: { $0.id == id }) == false)
            })

            app.clearRedisClientOverride()
            try await app.autoRevert()
            try await app.asyncShutdown()
        } catch {
            app.clearRedisClientOverride()
            try? await app.autoRevert()
            try? await app.asyncShutdown()
            throw error
        }
    }
}

private func createCataloguer(on db: any Database) async throws -> (username: String, password: String) {
    let user = DBUser(displayName: "Cataloguer", roles: Roles.cataloguer.rawValue, isActive: true)
    try await user.save(on: db)
    let username = "cataloguer"
    let password = "Password!23"
    let credential = DBCredential(
        userID: try user.requireID(),
        type: .usernameAndPassword,
        identifier: username,
        secret: try Bcrypt.hash(password)
    )
    try await credential.save(on: db)
    return (username, password)
}

private struct LoginResponse: Content {
    let accessToken: String
    let userId: UUID
}

private func loginCataloguer(app: Application, username: String, password: String) async throws -> LoginResponse {
    var response: LoginResponse?
    try await app.testing().test(.POST, "/v1/auth/login", beforeRequest: { req in
        req.headers.basicAuthorization = .init(username: username, password: password)
    }, afterResponse: { res async throws in
        #expect(res.status == .ok)
        response = try res.content.decode(LoginResponse.self)
    })
    guard let login = response else {
        Issue.record("Missing login response")
        throw Abort(.internalServerError)
    }
    return login
}
