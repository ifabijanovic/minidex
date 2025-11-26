import Foundation
import Logging
import NIOConcurrencyHelpers
import NIOCore
@preconcurrency import Redis

public enum InMemoryRedisError: Error, CustomStringConvertible {
    case unsupportedCommand(String)
    case invalidCommand(String)
    case simulatedFailure(String)

    public var description: String {
        switch self {
        case let .unsupportedCommand(command):
            return "Unsupported command: \(command)"
        case let .invalidCommand(command):
            return "Invalid command: \(command)"
        case let .simulatedFailure(command):
            return "Simulated failure for command: \(command)"
        }
    }
}

public final class InMemoryRedisDriver: @unchecked Sendable {
    public struct EntrySnapshot {
        public let data: Data
        public let expiresAt: Date?
    }

    public struct SetexCall {
        public let key: RedisKey
        public let ttl: Int
    }

    public struct Snapshot {
        public let entries: [RedisKey: EntrySnapshot]
        public let setexCalls: [SetexCall]
        public let deleteCalls: [[RedisKey]]
    }

    private struct Entry {
        var data: Data
        var expiresAt: Date?

        func isExpired(now: Date) -> Bool {
            guard let expiresAt else { return false }
            return now >= expiresAt
        }
    }

    private struct State {
        var entries: [RedisKey: Entry] = [:]
        var setexCalls: [SetexCall] = []
        var deleteCalls: [[RedisKey]] = []
        var failures: [String: InMemoryRedisError] = [:]
    }

    private let state = NIOLockedValueBox(State())
    private let allocator = ByteBufferAllocator()
    private let clock: () -> Date

    public init(clock: @escaping () -> Date = Date.init) {
        self.clock = clock
    }

    public func makeClient(on eventLoop: any EventLoop) -> any RedisClient {
        InMemoryRedisClient(eventLoop: eventLoop, driver: self)
    }

    public func snapshot() -> Snapshot {
        state.withLockedValue { state in
            purgeExpiredLocked(state: &state)
            let entries = state.entries.mapValues { EntrySnapshot(data: $0.data, expiresAt: $0.expiresAt) }
            return Snapshot(entries: entries, setexCalls: state.setexCalls, deleteCalls: state.deleteCalls)
        }
    }

    public func failNextCommand(_ command: String, error: InMemoryRedisError? = nil) {
        state.withLockedValue { state in
            state.failures[command.uppercased()] = error ?? .simulatedFailure(command)
        }
    }

    fileprivate func handle(command: String, arguments: [RESPValue]) throws -> RESPValue {
        let uppercased = command.uppercased()
        if let error = state.withLockedValue({ $0.failures.removeValue(forKey: uppercased) }) {
            throw error
        }

        switch uppercased {
        case "SETEX":
            return try handleSetex(arguments: arguments)
        case "GET":
            return try handleGet(arguments: arguments)
        case "DEL":
            return try handleDel(arguments: arguments)
        case "EXISTS":
            return try handleExists(arguments: arguments)
        default:
            throw InMemoryRedisError.unsupportedCommand(command)
        }
    }

    private func handleSetex(arguments: [RESPValue]) throws -> RESPValue {
        guard arguments.count == 3,
              let key = RedisKey(fromRESP: arguments[0]),
              let ttlString = arguments[1].string,
              let requestedTTL = Int(ttlString),
              let data = arguments[2].data
        else {
            throw InMemoryRedisError.invalidCommand("SETEX")
        }

        let ttl = max(1, requestedTTL)
        let expiresAt = clock().addingTimeInterval(TimeInterval(ttl))

        state.withLockedValue { state in
            state.entries[key] = Entry(data: data, expiresAt: expiresAt)
            state.setexCalls.append(SetexCall(key: key, ttl: ttl))
        }

        var buffer = allocator.buffer(capacity: 2)
        buffer.writeString("OK")
        return .simpleString(buffer)
    }

    private func handleGet(arguments: [RESPValue]) throws -> RESPValue {
        guard arguments.count == 1, let key = RedisKey(fromRESP: arguments[0]) else {
            throw InMemoryRedisError.invalidCommand("GET")
        }

        if let entry = state.withLockedValue({ state -> Entry? in
            purgeExpiredLocked(state: &state)
            return state.entries[key]
        }) {
            var buffer = allocator.buffer(capacity: entry.data.count)
            buffer.writeBytes(entry.data)
            return .bulkString(buffer)
        }

        return .null
    }

    private func handleDel(arguments: [RESPValue]) throws -> RESPValue {
        guard !arguments.isEmpty else {
            throw InMemoryRedisError.invalidCommand("DEL")
        }

        var removed = 0
        let keys: [RedisKey] = try arguments.map {
            guard let key = RedisKey(fromRESP: $0) else {
                throw InMemoryRedisError.invalidCommand("DEL")
            }
            return key
        }

        state.withLockedValue { state in
            purgeExpiredLocked(state: &state)
            for key in keys {
                if state.entries.removeValue(forKey: key) != nil {
                    removed += 1
                }
            }
            state.deleteCalls.append(keys)
        }

        return .integer(removed)
    }

    private func handleExists(arguments: [RESPValue]) throws -> RESPValue {
        guard !arguments.isEmpty else {
            throw InMemoryRedisError.invalidCommand("EXISTS")
        }

        let keys: [RedisKey] = try arguments.map {
            guard let key = RedisKey(fromRESP: $0) else {
                throw InMemoryRedisError.invalidCommand("EXISTS")
            }
            return key
        }

        let count = state.withLockedValue { state -> Int in
            purgeExpiredLocked(state: &state)
            return keys.reduce(into: 0) { result, key in
                if state.entries[key] != nil {
                    result += 1
                }
            }
        }

        return .integer(count)
    }

    private func purgeExpiredLocked(state: inout State) {
        let now = clock()
        state.entries = state.entries.filter { !$0.value.isExpired(now: now) }
    }
}

private final class InMemoryRedisClient: RedisClient {
    let eventLoop: any EventLoop
    private let driver: InMemoryRedisDriver

    init(eventLoop: any EventLoop, driver: InMemoryRedisDriver) {
        self.eventLoop = eventLoop
        self.driver = driver
    }

    func logging(to logger: Logger) -> any RedisClient {
        self
    }

    func send(command: String, with arguments: [RESPValue]) -> EventLoopFuture<RESPValue> {
        do {
            return try eventLoop.makeSucceededFuture(driver.handle(command: command, arguments: arguments))
        } catch {
            return eventLoop.makeFailedFuture(error)
        }
    }

    func subscribe(
        to channels: [RedisChannelName],
        messageReceiver receiver: @escaping RedisSubscriptionMessageReceiver,
        onSubscribe subscribeHandler: RedisSubscriptionChangeHandler?,
        onUnsubscribe unsubscribeHandler: RedisSubscriptionChangeHandler?
    ) -> EventLoopFuture<Void> {
        eventLoop.makeFailedFuture(InMemoryRedisError.unsupportedCommand("SUBSCRIBE"))
    }

    func psubscribe(
        to patterns: [String],
        messageReceiver receiver: @escaping RedisSubscriptionMessageReceiver,
        onSubscribe subscribeHandler: RedisSubscriptionChangeHandler?,
        onUnsubscribe unsubscribeHandler: RedisSubscriptionChangeHandler?
    ) -> EventLoopFuture<Void> {
        eventLoop.makeFailedFuture(InMemoryRedisError.unsupportedCommand("PSUBSCRIBE"))
    }

    func unsubscribe(from channels: [RedisChannelName]) -> EventLoopFuture<Void> {
        eventLoop.makeFailedFuture(InMemoryRedisError.unsupportedCommand("UNSUBSCRIBE"))
    }

    func punsubscribe(from patterns: [String]) -> EventLoopFuture<Void> {
        eventLoop.makeFailedFuture(InMemoryRedisError.unsupportedCommand("PUNSUBSCRIBE"))
    }
}

#if canImport(Testing)
import Testing
extension InMemoryRedisDriver {
    public func assertCleared(key: RedisKey) {
        let snapshot = self.snapshot()
        #expect(snapshot.entries[key] == nil)
        let keyDeleted = snapshot.deleteCalls.contains { $0.contains(key) }
        #expect(keyDeleted)
    }
}
#endif
