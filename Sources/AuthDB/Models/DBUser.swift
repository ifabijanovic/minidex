import Fluent
import Foundation

public final class DBUser: Model, @unchecked Sendable {
    public static let schema = "users"

    @ID
    public var id: UUID?

    @Field(key: "roles")
    public var roles: UInt

    @Field(key: "is_active")
    public var isActive: Bool

    @Timestamp(key: "created_at", on: .create)
    public var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update)
    public var updatedAt: Date?

    @Children(for: \.$user)
    public var credentials: [DBCredential]

    public init() {}

    public init(
        id: UUID? = nil,
        roles: UInt = 0,
        isActive: Bool = false,
    ) {
        self.id = id
        self.roles = roles
        self.isActive = isActive
    }
}

extension DBUser: CustomStringConvertible {
    public var description: String {
        id.map {
            "\($0.uuidString), \(roles), \(isActive)"
        } ?? "\(roles), \(isActive)"
    }
}
