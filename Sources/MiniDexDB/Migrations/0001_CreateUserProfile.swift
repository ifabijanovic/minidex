import Fluent
import SQLKit

struct Migration_0001_CreateUserProfile: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database
            .schema("user_profiles")
            .id()
            .field("user_id", .uuid, .required, .references("users", "id"))
            .field("display_name", .string)
            .field("avatar_url", .string)
            .field("created_at", .datetime, .required)
            .field("updated_at", .datetime, .required)
            .create()

        if let sqlDB = database as? any SQLDatabase {
            try await sqlDB
                .create(index: "idx_user_profiles_user_id")
                .on("user_profiles")
                .column("user_id")
                .unique() // 1-to-1
                .run()
        }
    }

    func revert(on database: any Database) async throws {
        if let sqlDB = database as? any SQLDatabase {
            try await sqlDB
                .drop(index: "idx_user_profiles_user_id")
                .run()
        }

        try await database
            .schema("user_profiles")
            .delete()
    }
}
