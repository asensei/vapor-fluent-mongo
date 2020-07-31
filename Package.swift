// swift-tools-version:5.2

//
//  Package.swift
//  FluentMongo
//
//  Created by Valerio Mazzeo on 30/11/2018.
//  Copyright © 2018 Asensei Inc. All rights reserved.
//

import PackageDescription

let package = Package(
    name: "FluentMongo",
    platforms: [
        .macOS(.v10_15)
    ],
    products: [
        .library(name: "FluentMongo", targets: ["FluentMongo"])
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/fluent-kit.git", .upToNextMajor(from: "1.6.0")),
        .package(url: "https://github.com/mongodb/mongo-swift-driver.git", .upToNextMajor(from: "1.0.0"))
    ],
    targets: [
        .target(name: "FluentMongo", dependencies: [
            .product(name: "FluentKit", package: "fluent-kit"),
            .product(name: "MongoSwift", package: "mongo-swift-driver")
        ]),
        .testTarget(name: "FluentMongoTests", dependencies: [
            "FluentMongo",
            .product(name: "FluentBenchmark", package: "fluent-kit")
        ])
    ]
)
