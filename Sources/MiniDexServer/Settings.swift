import FluentPostgresDriver
import Vapor

enum Settings {
    enum Auth {
        static let tokenLength = 32
        static let accessTokenExpiration: TimeInterval = 60 * 60 * 24
    }

    enum DB {
        static var hostname: String? { Environment.get("DATABASE_HOST") }
        static var port: Int? { Environment.get("DATABASE_PORT").flatMap(Int.init(_:)) }
        static var username: String? { Environment.get("DATABASE_USERNAME") }
        static var password: String? { Environment.get("DATABASE_PASSWORD") }
        static var database: String? { Environment.get("DATABASE_NAME") }
        static var adminUsername: String? { Environment.get("ADMIN_USERNAME") }
        static var adminPassword: String? { Environment.get("ADMIN_PASSWORD") }
    }
}

struct InvalidDBSettingsError: Error, CustomStringConvertible, CustomNSError {
    static let errorDomain = "hr.daylight.minidex.server"
    let key: String
    
    var description: String {
        "Missing required database setting: \(key)"
    }
    
    var errorUserInfo: [String: Any] {
        [NSLocalizedDescriptionKey: description]
    }
}
