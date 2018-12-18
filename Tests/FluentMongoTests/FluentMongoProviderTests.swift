//
//  FluentMongoProviderTests.swift
//  FluentMongoTests
//
//  Created by Valerio Mazzeo on 30/11/2018.
//  Copyright © 2018 Asensei Inc. All rights reserved.
//

import XCTest
import Fluent
import FluentBenchmark
@testable import FluentMongo

class FluentMongoProviderTests: XCTestCase {

    static let allTests = [
        ("testDistinct", testDistinct),
        ("testBenchmarkModels", testBenchmarkModels),
        ("testBenchmarkUpdate", testBenchmarkUpdate),
        ("testBenchmarkBugs", testBenchmarkBugs),
        ("testBenchmarkSort", testBenchmarkSort),
        ("testBenchmarkRange", testBenchmarkRange),
        ("testBenchmarkSubset", testBenchmarkSubset),
        ("testBenchmarkChunking", testBenchmarkChunking),
        ("testBenchmarkAggregate", testBenchmarkAggregate),
        ("testBenchmarkLifecycle", testBenchmarkLifecycle),
        ("testBenchmarkAutoincrement", testBenchmarkAutoincrement),
        ("testBenchmarkTimestampable", testBenchmarkTimestampable)
    ]

    var benchmarker: Benchmarker<MongoDatabase>!

    var database: MongoDatabase!

    override func setUp() {
        let eventLoop = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        do {
            let config = try MongoDatabaseConfig(
                host: "localhost",
                port: 27017,
                database: "vapor_database"
            )

            try MongoClient(connectionString: config.connectionURL.absoluteString).db(config.database).drop()
            self.database = MongoDatabase(config: config)
            self.benchmarker = try Benchmarker(self.database, on: eventLoop, onFail: XCTFail)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testDistinct() {
        do {
            let conn = try self.database.newConnection(on: MultiThreadedEventLoopGroup(numberOfThreads: 1)).wait()
            _ = try User(name: "Alice", age: 20).save(on: conn).wait()
            _ = try User(name: "Bob", age: 20).save(on: conn).wait()
            _ = try User(name: "Charlie", age: 20).save(on: conn).wait()
            _ = try User(name: "Bob", age: 19).save(on: conn).wait()
            _ = try User(name: "Charlie", age: 20).save(on: conn).wait()

            XCTAssertEqual(try User.query(on: conn).count().wait(), 5)
            XCTAssertEqual(try User.query(on: conn).distinct().count().wait(), 5)
            XCTAssertEqual(try User.query(on: conn).distinct().key(\.name).count().wait(), 3)
            XCTAssertEqual(try User.query(on: conn).distinct().key(\.name).key(\.age).count().wait(), 4)
            let users = try User.query(on: conn).distinct().key(\.name).all().wait().map { $0.name }
            XCTAssertEqual(users.count, 3)
            XCTAssertTrue(users.contains("Alice"))
            XCTAssertTrue(users.contains("Bob"))
            XCTAssertTrue(users.contains("Charlie"))
            let usersNameAge = try User.query(on: conn).distinct().key(\.name).key(\.age).all().wait()
            XCTAssertEqual(usersNameAge.count, 4)
            XCTAssertTrue(usersNameAge.contains(where: { $0.name == "Alice" && $0.age == 20 }))
            XCTAssertTrue(usersNameAge.contains(where: { $0.name == "Bob" && $0.age == 20 }))
            XCTAssertTrue(usersNameAge.contains(where: { $0.name == "Bob" && $0.age == 19 }))
            XCTAssertTrue(usersNameAge.contains(where: { $0.name == "Charlie" && $0.age == 20 }))
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testBenchmarkModels() {
        do {
            // TODO: https://github.com/vapor/fluent/pull/603
            try self.benchmarker.benchmarkModels()
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testBenchmarkUpdate() {
        do {
            try self.benchmarker.benchmarkUpdate()
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testBenchmarkBugs() {
        do {
            try self.benchmarker.benchmarkBugs()
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testBenchmarkSort() {
        do {
            try self.benchmarker.benchmarkSort()
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testBenchmarkRange() {
        do {
            try self.benchmarker.benchmarkRange()
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testBenchmarkSubset() {
        do {
            try self.benchmarker.benchmarkSubset()
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testBenchmarkChunking() {
        do {
            try self.benchmarker.benchmarkChunking()
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testBenchmarkAggregate() {
        do {
            try self.benchmarker.benchmarkAggregate()
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testBenchmarkLifecycle() {
        do {
            try self.benchmarker.benchmarkLifecycle()
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testBenchmarkAutoincrement() {
        do {
            try self.benchmarker.benchmarkAutoincrement()
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testBenchmarkTimestampable() throws {
        do {
            try self.benchmarker.benchmarkTimestampable()
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
}