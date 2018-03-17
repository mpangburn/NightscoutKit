// swift-tools-version:4.0

//
//  Package.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 3/17/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

import PackageDescription

let package = Package(
    name: "NightscoutKit",
    products: [
        .library(name: "NightscoutKit", targets: ["NightscoutKit"])
    ],
    targets: [
        .target(
            name: "NightscoutKit",
            dependencies: []
        )
    ]
)
