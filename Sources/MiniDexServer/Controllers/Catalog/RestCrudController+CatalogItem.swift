import AuthDB
import AuthAPI
import MiniDexDB
import Fluent
import VaporUtils
import Vapor

extension RestCrudController {
    /// Find one operation for catalog items with permission checks.
    ///
    /// - `admin` users can see all items.
    /// - `cataloguer` users can see their own items and all `limited` and `public` items.
    /// - `hobbyist` users can see their own items and all `public` items.
    func findOneCatalogItem(
        req: Request,
        userPath: KeyPath<DBModel, ParentProperty<DBModel, DBUser>>,
        visibilityPath: KeyPath<DBModel, CatalogItemVisibility>,
        query: (@Sendable (UUID) throws -> QueryBuilder<DBModel>)? = nil,
    ) async throws -> DBModel?
    {
        let user = try req.auth.require(AuthUser.self)
        let id: UUID = try req.parameters.require("id")
        let result: DBModel?
        if let query {
            result = try await query(id).first()
        } else {
            result = try await DBModel.find(id, on: req.db)
        }
        guard let result else { return nil }

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

    /// Find many operation for catalog items with permission checks.
    ///
    /// - `admin` users can see all items.
    /// - `cataloguer` users can see their own items and all `limited` and `public` items.
    /// - `hobbyist` users can see their own items and all `public` items.
    func findManyCatalogItems(
        req: Request,
        userPath: KeyPath<DBModel, ParentProperty<DBModel, DBUser>>,
        visibilityPath: KeyPath<DBModel, EnumProperty<DBModel, CatalogItemVisibility>>,
    ) throws -> QueryBuilder<DBModel> {
        let user = try req.auth.require(AuthUser.self)
        if user.roles.contains(.admin) {
            return DBModel.query(on: req.db)
        } else {
            let visibility: Set<CatalogItemVisibility> = user.roles.contains(.cataloguer)
                ? [.limited, .`public`]
                : [.`public`]

            return DBModel
                .query(on: req.db)
                .group(.or) { group in
                    group
                        .filter(userPath.appending(path: \.$id) == user.id)
                        .filter(visibilityPath ~~ visibility)
                }
        }
    }

    /// Create operation for catalog items with permission checks.
    ///
    /// - `admin` user can always create items.
    /// - `cataloguer` users can create `private` or `public` items.
    /// - `hobbyist` users can create `private` or `limited` items.
    func createCatalogItem(
        _ visibilityPath: KeyPath<PostDTO, CatalogItemVisibility>,
        makeModel: @Sendable @escaping (PostDTO, Request) throws -> DBModel,
    ) -> @Sendable (Request) async throws -> DTO {
        return create { dto, req in
            let user = try req.auth.require(AuthUser.self)

            if user.roles.contains(.admin) {
                return try makeModel(dto, req)
            }

            let visibility = dto[keyPath: visibilityPath]
            switch visibility {
            case .`private`:
                break
            case .limited:
                guard user.roles.contains(.hobbyist) else {
                    throw Abort(.forbidden)
                }
            case .`public`:
                guard user.roles.contains(.cataloguer) else {
                    throw Abort(.forbidden)
                }
            }
            return try makeModel(dto, req)
        }
    }

    /// Update operation for catalog items with permission checks.
    ///
    /// - `admin` user can always update items.
    /// - `cataloguer` users can update their own `private` and `limited` items and all `public` items.
    /// - `hobbyist` users can update their own `private` and `limited` items.
    func updateCatalogItem(
        createdByPath: KeyPath<DBModel, ParentProperty<DBModel, DBUser>>,
        visibilityDBPath: KeyPath<DBModel, CatalogItemVisibility>,
        visibilityDTOPath: KeyPath<PatchDTO, CatalogItemVisibility?>,
        mutate: @Sendable @escaping (DBModel, PatchDTO, Request) throws -> Void,
    ) -> @Sendable (Request) async throws -> DTO {
        return update { dbModel, dto, req in
            let user = try req.auth.require(AuthUser.self)

            if user.roles.contains(.admin) {
                return try mutate(dbModel, dto, req)
            }

            let isOwnedByUser = dbModel[keyPath: createdByPath].id == user.id
            let currentVisibility = dbModel[keyPath: visibilityDBPath]
            let desiredVisibility = dto[keyPath: visibilityDTOPath] ?? currentVisibility

            var canPatch = false
            if user.roles.contains(.hobbyist) {
                canPatch = isOwnedByUser
                    && (currentVisibility == .`private` || currentVisibility == .limited)
                    && (desiredVisibility == .`private` || desiredVisibility == .limited)
            }

            if user.roles.contains(.cataloguer) {
                canPatch = canPatch
                    || (currentVisibility == .`public` && desiredVisibility == .`public`)
                    || (isOwnedByUser && currentVisibility == desiredVisibility)
            }

            guard canPatch else { throw Abort(.forbidden) }
            return try mutate(dbModel, dto, req)
        }
    }

    /// Delete operation for catalog items with permission checks.
    ///
    /// - `admin` users can always delete any items.
    /// - `cataloguer` users can delete items they created or `public` items.
    /// - `hobbyist` users can delete items they created.
    func deleteCatalogItem(
        createdByPath: KeyPath<DBModel, ParentProperty<DBModel, DBUser>>,
        visibilityPath: KeyPath<DBModel, CatalogItemVisibility>,
    ) -> @Sendable (Request) async throws -> HTTPStatus {
        return delete { dbModel, req in
            let user = try req.auth.require(AuthUser.self)

            if user.roles.contains(.admin) {
                return true
            }

            let isOwnedByUser = dbModel[keyPath: createdByPath].id == user.id
            let visibility = dbModel[keyPath: visibilityPath]

            switch visibility {
            case .`private`:
                return isOwnedByUser
            case .limited:
                return isOwnedByUser
            case .`public`:
                return user.roles.contains(.cataloguer)
            }
        }
    }
}
