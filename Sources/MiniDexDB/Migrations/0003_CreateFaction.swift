import Fluent
import SQLKit

struct Migration_0003_CreateFaction: AsyncMigration {
    func prepare(on database: any Database) async throws {
        let catalogItemVisibility = try await database
            .enum("catalog_item_visibility")
            .read()

        try await database
            .schema("factions")
            .id()
            .field("name", .string, .required)
            .field("game_system_id", .uuid, .references("game_systems", "id", onDelete: .restrict))
            .field("parent_faction_id", .uuid, .references("factions", "id", onDelete: .restrict))
            .field("created_by", .uuid, .required, .references("users", "id"))
            .field("visibility", catalogItemVisibility, .required)
            .create()

        if let sqlDB = database as? any SQLDatabase {
            try await sqlDB
                .create(index: "idx_factions_creator_visibility")
                .on("factions")
                .column("created_by")
                .column("visibility")
                .run()

            try await sqlDB
                .create(index: "idx_factions_game_system_id")
                .on("factions")
                .column("game_system_id")
                .run()

            try await sqlDB
                .create(index: "idx_factions_parent_faction_id")
                .on("factions")
                .column("parent_faction_id")
                .run()
        }
    }

    func revert(on database: any Database) async throws {
        if let sqlDB = database as? any SQLDatabase {
            try await sqlDB
                .drop(index: "idx_factions_parent_faction_id")
                .run()

            try await sqlDB
                .drop(index: "idx_factions_game_system_id")
                .run()

            try await sqlDB
                .drop(index: "idx_factions_creator_visibility")
                .run()
        }

        try await database
            .schema("factions")
            .delete()
    }
}
