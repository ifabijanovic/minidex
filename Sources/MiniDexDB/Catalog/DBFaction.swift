import AuthDB
import Fluent
import Foundation

public final class DBFaction: Model, @unchecked Sendable {
    public static let schema = "factions"

    @ID
    public var id: UUID?

    @Field(key: "name")
    public var name: String

    @OptionalParent(key: "game_system_id")
    public var gameSystem: DBGameSystem?

    @OptionalParent(key: "parent_faction_id")
    public var parentFaction: DBFaction?

    @Parent(key: "created_by")
    public var createdBy: DBUser

    @Enum(key: "visibility")
    public var visibility: CatalogItemVisibility

    public init() {}

    public init(
        id: UUID? = nil,
        name: String,
        gameSystemID: UUID? = nil,
        parentFactionID: UUID? = nil,
        createdByID: UUID,
        visibility: CatalogItemVisibility,
    ) {
        self.id = id
        self.name = name
        self.$gameSystem.id = gameSystemID
        self.$parentFaction.id = parentFactionID
        self.$createdBy.id = createdByID
        self.visibility = visibility
    }
}

public final class DBParentFaction: ModelAlias {
    public static let name = "parent_factions"
    public let model = DBFaction()
    public init() {}
}

extension DBFaction: CustomStringConvertible {
    public var description: String {
        name
    }
}
