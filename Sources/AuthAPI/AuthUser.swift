import Vapor

public struct Roles: OptionSet, Codable, Sendable {
    public let rawValue: UInt

    public static let admin = Roles(rawValue: 1 << 0)

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }
}

public struct AuthUser: Content, Authenticatable {
    public var id: UUID
    public var roles: Roles
    public var isActive: Bool
    public var tokenID: UUID?
}
