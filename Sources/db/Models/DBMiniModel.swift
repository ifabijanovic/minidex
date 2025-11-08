import Fluent
import Foundation

public final class DBMiniModel: Model, @unchecked Sendable {
    public static let schema = "mini_models"

    @ID
    public var id: UUID?

    @Field(key: "name")
    public var name: String

    public init() {}

    public init(
        id: UUID? = nil,
        name: String
    ) {
        self.id = id
        self.name = name
    }
}

extension DBMiniModel: CustomStringConvertible {
    public var description: String {
        name
    }
}
