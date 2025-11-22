// swift-tools-version:6.2
import PackageDescription

let package = Package(
    name: "minidex",
    platforms: [
       .macOS(.v13)
    ],
    products: [
        .library(name: "AuthDB", targets: ["AuthDB"]),
        .library(name: "AuthAPI", targets: ["AuthAPI"]),
        .library(name: "MiniDexDB", targets: ["MiniDexDB"]),
    ],
    dependencies: [
        // 💧 A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", from: "4.115.0"),
        // 🗄 An ORM for SQL and NoSQL databases.
        .package(url: "https://github.com/vapor/fluent.git", from: "4.9.0"),
        // 🐘 Fluent driver for Postgres.
        .package(url: "https://github.com/vapor/fluent-postgres-driver.git", from: "2.8.0"),
        // 🔵 Non-blocking, event-driven networking for Swift. Used for custom executors
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.65.0"),
        .package(url: "https://github.com/vapor/redis.git", from: "4.0.0"),
        .package(url: "https://github.com/vapor/fluent-sqlite-driver.git", from: "4.5.0")
    ],
    targets: [
        .target(
            name: "AuthDB",
            dependencies: [
                .product(name: "Fluent", package: "fluent"),
            ],
            swiftSettings: swiftSettings,
        ),
        .target(
            name: "AuthAPI",
            dependencies: [
                .target(name: "AuthDB"),
                .target(name: "VaporRedisUtils"),
                .target(name: "VaporUtils"),
                .product(name: "Fluent", package: "fluent"),
                .product(name: "Redis", package: "redis"),
                .product(name: "Vapor", package: "vapor"),
            ],
            exclude: [
                "README.md",
            ],
            swiftSettings: swiftSettings,
        ),
        .target(
            name: "MiniDexDB",
            dependencies: [
                .target(name: "AuthDB"),
                .product(name: "Fluent", package: "fluent"),
            ],
            swiftSettings: swiftSettings,
        ),
        .executableTarget(
            name: "MiniDexServer",
            dependencies: [
                .target(name: "AuthAPI"),
                .target(name: "MiniDexDB"),
                .target(name: "VaporUtils"),
                .product(name: "Fluent", package: "fluent"),
                .product(name: "FluentPostgresDriver", package: "fluent-postgres-driver"),
                .product(name: "NIOCore", package: "swift-nio"),
                .product(name: "NIOPosix", package: "swift-nio"),
                .product(name: "Redis", package: "redis"),
                .product(name: "Vapor", package: "vapor"),
            ],
            swiftSettings: swiftSettings,
        ),
        .target(
            name: "VaporRedisUtils",
            dependencies: [
                .product(name: "Redis", package: "redis"),
                .product(name: "Vapor", package: "vapor"),
            ],
            swiftSettings: swiftSettings,
        ),
        .target(
            name: "VaporTestingUtils",
            dependencies: [
                .target(name: "AuthAPI"),
                .target(name: "AuthDB"),
                .target(name: "VaporRedisUtils"),
                .target(name: "VaporUtils"),
                .product(name: "Fluent", package: "fluent"),
                .product(name: "FluentSQLiteDriver", package: "fluent-sqlite-driver"),
                .product(name: "Redis", package: "redis"),
                .product(name: "VaporTesting", package: "vapor"),
            ],
            swiftSettings: swiftSettings,
        ),
        .target(
            name: "VaporUtils",
            dependencies: [
                .product(name: "Fluent", package: "fluent"),
                .product(name: "FluentPostgresDriver", package: "fluent-postgres-driver"),
                .product(name: "FluentSQLiteDriver", package: "fluent-sqlite-driver"),
                .product(name: "Vapor", package: "vapor"),
            ],
            swiftSettings: swiftSettings,
        ),
        .testTarget(
            name: "AuthAPITests",
            dependencies: [
                .target(name: "AuthAPI"),
                .target(name: "VaporTestingUtils"),
            ],
            swiftSettings: swiftSettings,
        ),
        .testTarget(
            name: "VaporUtilsTests",
            dependencies: [
                .target(name: "VaporUtils"),
            ],
            swiftSettings: swiftSettings,
        ),
        .testTarget(
            name: "VaporRedisUtilsTests",
            dependencies: [
                .target(name: "VaporRedisUtils"),
            ],
            swiftSettings: swiftSettings,
        ),
        .testTarget(
            name: "MiniDexServerTests",
            dependencies: [
                .target(name: "MiniDexServer"),
                .target(name: "VaporTestingUtils"),
            ],
            swiftSettings: swiftSettings,
        )
    ]
)

var swiftSettings: [SwiftSetting] {
    [
        .enableUpcomingFeature("ExistentialAny"),
        .treatAllWarnings(as: .error),
    ]
}
