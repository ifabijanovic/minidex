import Fluent
import SQLKit

struct Migration_0004_CreateUserAndCredential: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database
            .schema("users")
            .id()
            .field("display_name", .string)
            .field("created_at", .datetime, .required)
            .field("updated_at", .datetime, .required)
            .create()

        let credentialType = try await database
            .enum("credential_type")
            .case("usernameAndPassword")
            .create()

        try await database
            .schema("credentials")
            .id()
            .field("user_id", .uuid, .required, .references("users", "id"))
            .field("type", credentialType, .required)
            .field("identifier", .string, .required)
            .field("secret", .string)
            .field("created_at", .datetime, .required)
            .field("updated_at", .datetime, .required)
            .create()

        if let sqlDB = database as? any SQLDatabase {
            try await sqlDB
                .create(index: "idx_credentials_type_identifier")
                .on("credentials")
                .column("type")
                .column("identifier")
                .unique()
                .run()
        }
    }

    func revert(on database: any Database) async throws {
        if let sqlDB = database as? any SQLDatabase {
            try await sqlDB
                .drop(index: "idx_credentials_type_identifier")
                .run()
        }

        try await database
            .schema("credentials")
            .delete()

        try await database
            .enum("credential_type")
            .delete()

        try await database
            .schema("users")
            .delete()
    }
}
