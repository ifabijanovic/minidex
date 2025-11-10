import AuthDB
import Fluent
import Vapor

public struct TokenAuthenticator: AsyncBearerAuthenticator {
    public init() {}

    public func authenticate(bearer: BearerAuthorization, for request: Request) async throws {
        guard let hash = bearer.token
            .base64URLDecodedData()
            .map(SHA256.hash(data:))
            .map(Data.init(_:))
        else { return }

        let token = try await DBUserToken
            .query(on: request.db)
            .join(DBUser.self, on: \DBUserToken.$user.$id == \DBUser.$id)
            .filter(\.$value == hash)
            .first()

        if let token,
           !token.isRevoked,
           token.expiresAt.timeIntervalSinceNow > 0
        {
            let dbUser = try token.joined(DBUser.self)
            let user = try User(
                id: dbUser.requireID(),
                displayName: dbUser.displayName,
            )
            request.auth.login(user)
        }
    }
}
