import AuthDB
import Fluent
import Foundation

public final class DBGameSystem: Model, @unchecked Sendable {
    public static let schema = "game_systems"

    @ID
    public var id: UUID?

    @Field(key: "name")
    public var name: String

    @OptionalField(key: "publisher")
    public var publisher: String?

    @OptionalField(key: "release_year")
    public var releaseYear: UInt?

    @OptionalField(key: "website")
    public var website: String?

    @Parent(key: "created_by")
    public var createdBy: DBUser

    @Enum(key: "visibility")
    public var visibility: CatalogItemVisibility

    public init() {}

    public init(
        id: UUID? = nil,
        name: String,
        publisher: String? = nil,
        releaseYear: UInt? = nil,
        website: String? = nil,
        createdByID: UUID,
        visibility: CatalogItemVisibility,
    ) {
        self.id = id
        self.name = name
        self.publisher = publisher
        self.releaseYear = releaseYear
        self.website = website
        self.$createdBy.id = createdByID
        self.visibility = visibility
    }
}

extension DBGameSystem: CustomStringConvertible {
    public var description: String {
        name
    }
}
