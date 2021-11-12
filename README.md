# vapor-fluent-mongo

![Swift](https://img.shields.io/badge/swift-5.5-orange.svg)
[![Build Status](https://travis-ci.com/asensei/vapor-fluent-mongo.svg?token=eSrCssnzja3G3GciyhUB&branch=master)](https://travis-ci.com/asensei/vapor-fluent-mongo)

Mongo driver for Fluent `4.x`.

## Environment Variables

| Name    | Required | Default | Value (e.g.) | Description |
| ------------- |:-------------:|:-------------:|:-------------:|:-------------|
| `FLUENT_MONGO_CONNECTION_URL` | ✔ | `-` | `mongodb://127.0.0.1:27017/vapor` | Mongo connection string. |

## Getting Started

### Install FluentMongo

*Please follow the instructions in the previous section on installing the MongoDB C Driver before proceeding.*

Add FluentMongo to your dependencies in `Package.swift`:

```swift
// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "MyPackage",
    dependencies: [
        .package(url: "https://github.com/asensei/fluent-mongo.git", from: "VERSION.STRING.HERE"),
    ],
    targets: [
        .target(name: "MyPackage", dependencies: ["FluentMongo"])
    ]
)
```
