import Fluent

struct Migration_0001_CreateMini: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database
            .schema("minis")
            .id()
            .field("name", .string, .required)
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database
            .schema("minis")
            .delete()
    }
}
