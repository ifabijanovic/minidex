import Vapor

extension Request {
    struct TokenClientKey: StorageKey {
        typealias Value = TokenClient
    }

    public var tokenClient: TokenClient {
        if let client = storage[TokenClientKey.self] {
            return client
        }
        let client = TokenClient.live(req: self)
        storage[TokenClientKey.self] = client
        return client
    }
}
