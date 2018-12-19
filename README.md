# vapor-fluent-mongo

![Swift](https://img.shields.io/badge/swift-4.2-orange.svg)
[![Build Status](https://travis-ci.com/asensei/vapor-fluent-mongo.svg?token=eSrCssnzja3G3GciyhUB&branch=master)](https://travis-ci.com/asensei/vapor-fluent-mongo)

Mongo driver for Fluent `3.x`.

## Environment Variables

| Name    | Required | Default | Value (e.g.) | Description |
| ------------- |:-------------:|:-------------:|:-------------:|:-------------|
| `FLUENT_MONGO_CONNECTION_URL` | ✔ | `-` | `mongodb://127.0.0.1:27017/vapor` | Mongo connection string. |

## Getting Started

### Install the MongoDB C Driver
The driver wraps the MongoDB C driver, and using it requires having the C driver's two components, `libbson` and `libmongoc`, installed on your system. **The minimum required version of the C Driver is 1.13.0**.

On a Mac, you can install both components at once using [Homebrew](https://brew.sh/):
`brew install mongo-c-driver`.

On Linux: please follow the [instructions](http://mongoc.org/libmongoc/current/installing.html#building-on-unix) from `libmongoc`'s documentation. Note that the versions provided by your package manager may be too old, in which case you can follow the instructions for building and installing from source.


### Install FluentMongo

*Please follow the instructions in the previous section on installing the MongoDB C Driver before proceeding.*

Add FluentMongo to your dependencies in `Package.swift`:

```swift
// swift-tools-version:4.2
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
