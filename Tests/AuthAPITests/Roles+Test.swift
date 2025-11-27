import AuthAPI

extension Roles {
    static let tester = Roles(rawValue: 1 << 1)
}

extension RolesConverter {
    static let test = RolesConverter(
        toStrings: { roles in
            var result = Set<String>()
            if roles.contains(.admin) { result.insert("admin") }
            if roles.contains(.tester) { result.insert("tester") }
            return result
        },
        toRoles: { strings in
            var result = Roles()
            if strings.contains("admin") { result.insert(.admin) }
            if strings.contains("tester") { result.insert(.tester) }
            return result
        }
    )
}
