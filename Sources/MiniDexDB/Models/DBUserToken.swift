import Fluent
import Foundation

public enum UserTokenType: String, Codable, Sendable {
    case access
}

public final class DBUserToken: Model, @unchecked Sendable {
    public static let schema = "user_tokens"

    @ID
    public var id: UUID?

    @Parent(key: "user_id")
    public var user: DBUser

    @Enum(key: "type")
    public var type: UserTokenType

    @Field(key: "value")
    public var value: String

    @Field(key: "expires_at")
    public var expiresAt: Date

    @Timestamp(key: "created_at", on: .create)
    public var createdAt: Date?

    @Field(key: "is_revoked")
    public var isRevoked: Bool

    public init() {}

    public init(
        id: UUID? = nil,
        userID: UUID,
        type: UserTokenType,
        value: String,
        expiresAt: Date,
        isRevoked: Bool = false,
    ) {
        self.id = id
        self.$user.id = userID
        self.type = type
        self.value = value
        self.expiresAt = expiresAt
        self.isRevoked = isRevoked
    }
}
