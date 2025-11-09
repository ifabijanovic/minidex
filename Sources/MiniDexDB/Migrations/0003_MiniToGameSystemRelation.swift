import Fluent

struct Migration_0003_MiniToGameSystemRelation: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database
            .schema("minis")
            .field("game_system_id", .uuid, .required, .references("game_systems", "id"))
            .update()
    }

    func revert(on database: any Database) async throws {
        try await database
            .schema("minis")
            .deleteField("game_system_id")
            .update()
    }
}
