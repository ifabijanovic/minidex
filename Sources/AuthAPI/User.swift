import Vapor

public struct User: Content, Authenticatable {
    public var id: UUID
    public var displayName: String?
}
