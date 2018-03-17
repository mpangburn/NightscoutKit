// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "NightscoutKit",
    products: [
        .library(name: "NightscoutKit", targets: ["NightscoutKit"])
    ],
    dependencies: [
        .package(url: "https://github.com/mpangburn/CCommonCrypto", .branch("master"))
    ],
    targets: [
        .target(
            name: "NightscoutKit",
            dependencies: []
        )
    ]
)
