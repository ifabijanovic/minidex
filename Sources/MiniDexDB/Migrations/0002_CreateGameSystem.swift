import Fluent

struct Migration_0002_CreateGameSystem: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database
            .schema("game_systems")
            .id()
            .field("name", .string, .required)
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database
            .schema("game_systems")
            .delete()
    }
}
