@testable import AuthAPI
import AuthDB
import Crypto
import Fluent
import Testing
import Vapor
import VaporTesting
import VaporRedisUtils
import VaporUtils
@preconcurrency import Redis

struct LoginResponse: Content {
    let accessToken: String
    let expiresIn: Int
    let userId: UUID
}

enum AuthAPITestHelpers {
    @discardableResult
    static func createUser(
        on db: any Database,
        username: String,
        password: String = "Password!23",
        roles: Roles,
        isActive: Bool = true,
    ) async throws -> DBUser {
        let user = DBUser(roles: roles.rawValue, isActive: isActive)
        try await user.save(on: db)

        let credential = DBCredential(
            userID: try user.requireID(),
            type: .usernameAndPassword,
            identifier: username,
            secret: try Bcrypt.hash(password)
        )
        try await credential.save(on: db)

        return user
    }

    static func login(
        app: Application,
        username: String,
        password: String
    ) async throws -> LoginResponse {
        var response: LoginResponse?
        try await app.testing().test(
            .POST,
            "v1/auth/login",
            beforeRequest: { req in
                req.headers.basicAuthorization = .init(username: username, password: password)
            },
            afterResponse: { res async throws in
                #expect(res.status == .ok)
                response = try res.content.decode(LoginResponse.self)
            }
        )
        guard let loginResponse = response else {
            Issue.record("Login response missing")
            throw Abort(.internalServerError)
        }
        return loginResponse
    }

    static func authorize(_ req: inout TestingHTTPRequest, token: String) {
        req.headers.bearerAuthorization = .init(token: token)
    }

    static func assertCacheCleared(for login: LoginResponse, redis: InMemoryRedisDriver) throws {
        let snapshot = redis.snapshot()
        let userKey = RedisKey("token:\(login.accessToken)")
        guard let hashedAccessToken = TokenAuthenticator.hashAccessToken(login.accessToken) else {
            throw Abort(.internalServerError, reason: "Failed to decode access token")
        }
        let hashedKey = RedisKey("token_hash:\(hashedAccessToken.base64URLEncodedString())")

        #expect(snapshot.entries[userKey] == nil)
        #expect(snapshot.entries[hashedKey] == nil)

        let userKeyDeleted = snapshot.deleteCalls.contains { $0.contains(userKey) }
        let hashedKeyDeleted = snapshot.deleteCalls.contains { $0.contains(hashedKey) }

        #expect(userKeyDeleted)
        #expect(hashedKeyDeleted)
    }
}
