// swift-tools-version:6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let swiftSettings: [SwiftSetting] = [
    .enableUpcomingFeature("ExistentialAny"),
    .enableUpcomingFeature("StrictConcurrency"),
]

let package = Package(
    name: "SQLyra",
    platforms: [
        .macOS(.v12),
        .iOS(.v12),
    ],
    products: [
        .library(
            name: "SQLyra",
            targets: ["SQLyra"]
        )
    ],
    targets: [
        .target(
            name: "SQLyra",
            dependencies: [
                .target(name: "SQLite3", condition: .when(platforms: [.linux]))
            ],
            swiftSettings: swiftSettings,
        ),
        .systemLibrary(
            name: "SQLite3",
            pkgConfig: "sqlite3",
            providers: [
                .apt(["libsqlite3-dev"]),
                .brew(["sqlite3"]),
            ]
        ),
        .testTarget(
            name: "SQLyraTests",
            dependencies: ["SQLyra"],
            swiftSettings: swiftSettings
        ),
    ]
)
