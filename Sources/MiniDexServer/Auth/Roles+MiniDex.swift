import AuthAPI

extension Roles {
    /// Can access their own collection
    static let hobbyist = Roles(rawValue: 1 << 1)
    /// Can make changes to game systems and profiles
    static let cataloguer = Roles(rawValue: 1 << 2)

    var asStringSet: Set<String> {
        var result = Set<String>()
        if contains(.admin) { result.insert("admin") }
        if contains(.hobbyist) { result.insert("hobbyist") }
        if contains(.cataloguer) { result.insert("cataloguer") }
        return result
    }
}
