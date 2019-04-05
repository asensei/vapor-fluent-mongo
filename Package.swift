// swift-tools-version:5.0

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
    products: [
      .library(name: "FluentMongo", targets: ["FluentMongo"])
    ],
    dependencies: [
      .package(url: "https://github.com/vapor/core.git", .upToNextMajor(from: "3.8.0")),
      .package(url: "https://github.com/vapor/fluent.git", .upToNextMajor(from: "3.1.3")),
      .package(url: "https://github.com/mongodb/mongo-swift-driver.git", .upToNextMajor(from: "0.0.9"))
    ],
    targets: [
        .target(name: "FluentMongo", dependencies: ["Async", "Fluent", "MongoSwift"]),
        .testTarget(name: "FluentMongoTests", dependencies: ["FluentMongo", "FluentBenchmark"])
    ]
)
