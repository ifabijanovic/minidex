import Fluent

public func dbMigrations() -> [any Migration] {
    [
        M_0001_CreateMiniModel(),
    ]
}
