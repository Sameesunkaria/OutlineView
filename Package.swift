// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "OutlineView",
    platforms: [
      .macOS(.v11)
    ],
    products: [
        .library(
            name: "OutlineView",
            targets: ["OutlineView"]),
    ],
    targets: [
        .target(
            name: "OutlineView",
            dependencies: []),
        .testTarget(
            name: "OutlineViewTests",
            dependencies: ["OutlineView"]),
    ]
)
