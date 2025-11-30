import Foundation
import Vapor

/// Wrapper for AuthUser with integrity checksum to prevent cache tampering
struct CachedAuthUser: Codable, Sendable {
    let user: AuthUser
    let checksum: String
    
    init(user: AuthUser, checksumSecret: String) {
        self.user = user
        self.checksum = Self.computeChecksum(user: user, secret: checksumSecret)
    }

    func isValid(secret: String) -> Bool {
        let expectedChecksum = Self.computeChecksum(user: user, secret: secret)
        return checksum == expectedChecksum
    }

    private static func computeChecksum(user: AuthUser, secret: String) -> String {
        let data = Self.serializeUser(user)
        let secretData = Data(secret.utf8)
        let hmac = HMAC<SHA256>.authenticationCode(for: data, using: SymmetricKey(data: secretData))
        return Data(hmac).base64URLEncodedString()
    }

    private static func serializeUser(_ user: AuthUser) -> Data {
        var components: [String] = []
        components.append(user.id.uuidString)
        components.append(String(user.roles.rawValue))
        components.append(user.isActive ? "1" : "0")
        if let tokenID = user.tokenID {
            components.append(tokenID.uuidString)
        } else {
            components.append("")
        }
        let serialized = components.joined(separator: "|")
        return Data(serialized.utf8)
    }
}
