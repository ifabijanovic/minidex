import Fluent

public enum MiniDexDB {
    public static var migrations: [any Migration] {
        [
            Migration_0001_CreateUserProfile(),
            Migration_0002_CreateGameSystem(),
        ]
    }
}
