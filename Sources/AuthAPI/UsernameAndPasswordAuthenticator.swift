import AuthDB
import Fluent
import Vapor

public struct UsernameAndPasswordAuthenticator: AsyncBasicAuthenticator {
    public init() {}

    public func authenticate(basic: BasicAuthorization, for request: Request) async throws {
        let credential = try await DBCredential
            .query(on: request.db)
            .join(DBUser.self, on: \DBCredential.$user.$id == \DBUser.$id)
            .filter(\.$type == .usernameAndPassword)
            .filter(\.$identifier == basic.username)
            .first()

        if let credential,
           let secret = credential.secret,
           try Bcrypt.verify(basic.password, created: secret)
        {
            let dbUser = try credential.joined(DBUser.self)
            let user = try User(
                id: dbUser.requireID(),
                displayName: dbUser.displayName,
            )
            request.auth.login(user)
        }
    }
}
