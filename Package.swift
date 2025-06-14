// swift-tools-version:6.1

/**
 *  Files
 *  Copyright (c) John Sundell 2017
 *  Licensed under the MIT license. See LICENSE file.
 */

import PackageDescription

let package = Package(
    name: "Files",
    platforms: [
        .macOS(.v15),
        .iOS(.v18),
    ],
    products: [
        .library(name: "Files", targets: ["Files"])
    ],
    targets: [
        .target(
            name: "Files",
            path: "Sources"
        ),
        .testTarget(
            name: "FilesTests",
            dependencies: ["Files"]
        )
    ]
)
