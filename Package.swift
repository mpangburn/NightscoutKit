// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "NightscoutKit",
    products: [
        .library(name: "NightscoutKit", targets: ["NightscoutKit"])
    ],
    dependencies: [
        .package(url: "https://github.com/mpangburn/CCommonCrypto", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "NightscoutKit",
            dependencies: []
        )
    ]
)
