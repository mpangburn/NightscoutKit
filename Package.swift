// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "NightscoutKit",
    platforms: [
        .macOS(.v10_12), .iOS(.v12), .watchOS(.v5), .tvOS(.v11)
    ],
    products: [
        .library(name: "NightscoutKit", targets: ["NightscoutKit"])
    ],
    dependencies: [
        .package(url: "https://github.com/mpangburn/Oxygen", .branch("master"))
    ],
    targets: [
        .target(
            name: "NightscoutKit",
            dependencies: ["Oxygen"] 
        )
    ]
)
