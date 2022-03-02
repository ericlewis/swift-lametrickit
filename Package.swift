// swift-tools-version: 5.5

import PackageDescription

let package = Package(
    name: "swift-lametrickit",
    platforms: [.iOS(.v13), .macOS(.v10_15), .tvOS(.v13), .watchOS(.v6)],
    products: [
        .library(
            name: "LaMetricKit",
            targets: ["LaMetricKit"]),
    ],
    targets: [
        .target(
            name: "LaMetricKit",
            dependencies: []),
    ]
)
