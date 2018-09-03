// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "NightscoutKit",
    products: [
        .library(name: "NightscoutKit", targets: ["NightscoutKit"])
    ],
    dependencies: [

    ],
    targets: [
        .target(
            name: "NightscoutKit",
            dependencies: []
        )
    ]
)
