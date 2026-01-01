// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftFormatPackage",
    products: [
        .library(name: "SwiftFormatPackage", targets: ["SwiftFormatPackage"]),
    ],
    dependencies: [
        .package(url: "https://github.com/nicklockwood/SwiftFormat", .upToNextMajor(from: "0.58.7")),
    ],
    targets: [
        .target(
            name: "SwiftFormatPackage",
            dependencies: []
        ),
    ]
)
