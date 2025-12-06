import Fluent
import SQLKit

struct Migration_0002_CreateGameSystem: AsyncMigration {
    func prepare(on database: any Database) async throws {
        let catalogItemVisibility = try await database
            .enum("catalog_item_visibility")
            .case("private")
            .case("limited")
            .case("public")
            .create()

        try await database
            .schema("game_systems")
            .id()
            .field("name", .string, .required)
            .field("publisher", .string)
            .field("release_year", .uint)
            .field("website", .string)
            .field("created_by", .uuid, .required, .references("users", "id"))
            .field("visibility", catalogItemVisibility, .required)
            .create()

        if let sqlDB = database as? any SQLDatabase {
            try await sqlDB
                .create(index: "idx_game_systems_creator_visibility")
                .on("game_systems")
                .column("created_by")
                .column("visibility")
                .run()
        }
    }

    func revert(on database: any Database) async throws {
        if let sqlDB = database as? any SQLDatabase {
            try await sqlDB
                .drop(index: "idx_game_systems_creator_visibility")
                .run()
        }

        try await database
            .schema("game_systems")
            .delete()

        try await database
            .enum("catalog_item_visibility")
            .delete()
    }
}
