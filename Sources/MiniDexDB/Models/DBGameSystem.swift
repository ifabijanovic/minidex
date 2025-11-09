import Fluent

public final class DBGameSystem: Model, @unchecked Sendable {
    public static let schema = "game_systems"

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

extension DBGameSystem: CustomStringConvertible {
    public var description: String {
        name
    }
}
