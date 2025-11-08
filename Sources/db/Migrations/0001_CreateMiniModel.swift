import Fluent

struct M_0001_CreateMiniModel: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database
            .schema("mini_models")
            .id()
            .field("name", .string, .required)
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database
            .schema("mini_models")
            .delete()
    }
}
