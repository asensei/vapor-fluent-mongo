// swift-tools-version:5.1

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
      .package(url: "https://github.com/vapor/core.git", .upToNextMajor(from: "3.9.2")),
      .package(url: "https://github.com/vapor/fluent.git", .upToNextMajor(from: "3.2.1")),
      .package(url: "https://github.com/mongodb/mongo-swift-driver.git", .upToNextMinor(from: "0.2.0"))
    ],
    targets: [
        .target(name: "FluentMongo", dependencies: ["Async", "Fluent", "MongoSwift"]),
        .testTarget(name: "FluentMongoTests", dependencies: ["FluentMongo", "FluentBenchmark"])
    ]
)
