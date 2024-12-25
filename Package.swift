// swift-tools-version:5.9
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
            dependencies: [],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "SQLyraTests",
            dependencies: ["SQLyra"],
            swiftSettings: swiftSettings
        ),
    ]
)
