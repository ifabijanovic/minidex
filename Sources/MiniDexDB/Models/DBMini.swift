import Fluent

public final class DBMini: Model, @unchecked Sendable {
    public static let schema = "minis"

    @ID
    public var id: UUID?

    @Field(key: "name")
    public var name: String

    @Parent(key: "game_system_id")
    public var gameSystem: DBGameSystem

    public init() {}

    public init(
        id: UUID? = nil,
        name: String,
        gameSystemID: UUID,
    ) {
        self.id = id
        self.name = name
        self.$gameSystem.id = gameSystemID
    }
}

extension DBMini: CustomStringConvertible {
    public var description: String {
        name
    }
}
