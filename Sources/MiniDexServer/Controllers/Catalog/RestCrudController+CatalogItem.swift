import AuthDB
import AuthAPI
import MiniDexDB
import Fluent
import VaporUtils
import Vapor

extension RestCrudController {
    func findOneCatalogItem<T>(
        req: Request,
        userPath: KeyPath<T, ParentProperty<T, DBUser>>,
        visibilityPath: KeyPath<T, CatalogItemVisibility>,
    ) async throws -> T?
    where T: Model, T.IDValue == UUID
    {
        let user = try req.auth.require(AuthUser.self)
        guard let result = try await T.find(req.parameters.require("id"), on: req.db) else { return nil }
        if user.roles.contains(.admin) {
            return result
        } else {
            let visibility: Set<CatalogItemVisibility> = user.roles.contains(.cataloguer)
                ? [.limited, .`public`]
                : [.`public`]

            if result[keyPath: userPath].id == user.id || visibility.contains(result[keyPath: visibilityPath]) {
                return result
            }
        }
        return nil
    }

    func findManyCatalogItems<T: Model>(
        req: Request,
        userPath: KeyPath<T, ParentProperty<T, DBUser>>,
        visibilityPath: KeyPath<T, EnumProperty<T, CatalogItemVisibility>>,
    ) throws -> QueryBuilder<T> {
        let user = try req.auth.require(AuthUser.self)
        if user.roles.contains(.admin) {
            return T.query(on: req.db)
        } else {
            let visibility: Set<CatalogItemVisibility> = user.roles.contains(.cataloguer)
                ? [.limited, .`public`]
                : [.`public`]

            return T
                .query(on: req.db)
                .group(.or) { group in
                    group
                        .filter(userPath.appending(path: \.$id) == user.id)
                        .filter(visibilityPath ~~ visibility)
                }
        }
    }
}
