import AuthDB
import AuthAPI
import Fluent
import Vapor

struct Migration_CreateAdminUser: AsyncMigration {
    let logger: Logger
    
    func prepare(on database: any Database) async throws {
        guard let username = Settings.DB.adminUsername else { throw InvalidDBSettingsError(key: "ADMIN_USERNAME") }
        guard let password = Settings.DB.adminPassword else { throw InvalidDBSettingsError(key: "ADMIN_PASSWORD") }

        if try await DBCredential
            .query(on: database)
            .filter(\.$type == .usernameAndPassword)
            .filter(\.$identifier == username)
            .first() != nil
        {
            logger.info("Admin user already exists")
            return
        }

        try validate(password: password)
        let hashedPassword = try Bcrypt.hash(password)

        try await database.transaction { db in
            let user = DBUser(
                roles: Roles.admin.rawValue,
                isActive: true,
            )
            try await user.save(on: db)

            let credential = DBCredential(
                userID: try user.requireID(),
                type: .usernameAndPassword,
                identifier: username,
                secret: hashedPassword,
            )
            try await credential.save(on: db)
        }

        // Audit logging
        logger.info("Admin user created", metadata: [
            "username": .string(username),
            "roles": .stringConvertible(Roles.admin.rawValue)
        ])
    }

    func revert(on database: any Database) async throws {
        guard let username = Settings.DB.adminUsername else { throw InvalidDBSettingsError(key: "ADMIN_USERNAME") }

        try await database.transaction { db in
            let credential = try await DBCredential
                .query(on: db)
                .filter(\.$type == .usernameAndPassword)
                .filter(\.$identifier == username)
                .first()
            try await credential?.delete(on: db)
            try await credential?.user.delete(on: db)
        }
    }

    private func validate(password: String) throws {
        guard
            password.count >= 12,
            password.rangeOfCharacter(from: CharacterSet.uppercaseLetters) != nil,
            password.rangeOfCharacter(from: CharacterSet.lowercaseLetters) != nil,
            password.rangeOfCharacter(from: CharacterSet.decimalDigits) != nil
        else {
            throw Abort(
                .internalServerError,
                reason: "Admin password must be at least 12 characters and contain uppercase, lowercase, and numbers"
            )
        }
    }
}
