// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "LokiLogger",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .tvOS(.v17),
        .watchOS(.v10)
    ],
    products: [
        .library(
            name: "LokiLogger",
            targets: ["LokiLogger"]
        ),
    ],
    targets: [
        .target(
            name: "LokiLogger",
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        ),
        .testTarget(
            name: "LokiLoggerTests",
            dependencies: ["LokiLogger"],
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        ),
    ]
)
