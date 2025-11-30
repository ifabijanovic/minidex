import AuthDB
import Fluent
import Vapor

extension TokenClient {
    public static func live(req: Request) -> TokenClient {
        .init(
            generateToken: Self.generateToken(length:),
            isTokenValid: Self.isTokenValid(token:),
            hashToken: Self.hash(token:),
            revoke: { token, db in
                token.isRevoked = true
                try await token.save(on: db ?? req.db)

                let tokenID = try token.requireID()
                req.logger.debug("Revoked tokenID: \(tokenID)")

                await req.redisClient.invalidate(
                    hashedAccessToken: token.value.base64URLEncodedString(),
                    logger: req.logger
                )
            },
            revokeAllActiveTokens: { userID, db in
                let allTokens = try await DBUserToken
                    .query(on: db ?? req.db)
                    .filter(\.$user.$id == userID)
                    .all()

                try await DBUserToken
                    .query(on: db ?? req.db)
                    .filter(\.$user.$id == userID)
                    .filter(\.$isRevoked == false)
                    .set(\.$isRevoked, to: true)
                    .update()

                for token in allTokens {
                    let hashed = token.value.base64URLEncodedString()
                    await req.redisClient.invalidate(
                        hashedAccessToken: hashed,
                        logger: req.logger
                    )
                }

                req.logger.debug("Revoked all active tokens for userID: \(userID)")
            }
        )
    }

    static func userCacheKey(accessToken: String) -> String {
        "token:\(accessToken)"
    }

    static func tokenLookupKey(hashedAccessToken: String) -> String {
        "token_hash:\(hashedAccessToken)"
    }

    static func generateToken(length: Int) -> Token {
        var bytes = [UInt8](repeating: 0, count: length)
        var rng = SystemRandomNumberGenerator()
        for i in 0..<length {
            bytes[i] = UInt8.random(in: 0...255, using: &rng)
        }
        let raw = Data(bytes)
        let hashed = Data(SHA256.hash(data: raw))

        return .init(
            rawEncoded: raw.base64URLEncodedString(),
            hashed: hashed,
            hashedEncoded: hashed.base64URLEncodedString(),
        )
    }

    static func isTokenValid(token: DBUserToken) -> Bool {
        !token.isRevoked && token.expiresAt.timeIntervalSinceNow > 0
    }

    static func hash(token: String) -> Data? {
        token
            .base64URLDecodedData()
            .map(SHA256.hash(data:))
            .map(Data.init(_:))
    }
}
