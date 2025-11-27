import Redis
import Vapor

#if DEBUG
extension Application {
    private struct RedisClientFactoryKey: StorageKey {
        typealias Value = @Sendable (Request) -> any RedisClient
    }

    /// Override the Redis client used for incoming requests.
    /// Useful for testing or providing custom routing logic without reconfiguring
    /// the global Redis connection pool.
    public func useRedisClientOverride(_ factory: @escaping @Sendable (Request) -> any RedisClient) {
        self.storage[RedisClientFactoryKey.self] = factory
    }

    /// Removes any redis client override previously registered via ``useRedisClientOverride(_:)``.
    public func clearRedisClientOverride() {
        self.storage[RedisClientFactoryKey.self] = nil
    }

    fileprivate func redisClientOverride(for request: Request) -> (any RedisClient)? {
        self.storage[RedisClientFactoryKey.self]?(request)
    }
}
#endif

extension Request {
    /// Returns the request-scoped Redis client override if one was configured (debug builds only),
    /// falling back to Vapor's standard `request.redis` connection otherwise.
    public var redisClient: any RedisClient {
#if DEBUG
        if let override = self.application.redisClientOverride(for: self) {
            return override
        }
#endif
        return self.redis
    }
}
