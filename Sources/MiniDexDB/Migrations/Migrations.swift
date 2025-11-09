import Fluent

public enum Migrations {
    public static var all: [any Migration] {
        [
            Migration_0001_CreateMini(),
            Migration_0002_CreateGameSystem(),
            Migration_0003_MiniToGameSystemRelation(),
        ]
    }
}
