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
import MongoSwift
@testable import FluentMongo

class FluentMongoProviderTests: XCTestCase {

    static let allTests = [
        ("testIndex", testIndex),
        ("testModels", testModels),
        ("testJoin", testJoin),
        ("testDistinct", testDistinct),
        ("testMigration", testMigration),
        //("testBenchmarkModels", testBenchmarkModels),
        ("testBenchmarkUpdate", testBenchmarkUpdate),
        ("testBenchmarkBugs", testBenchmarkBugs),
        ("testBenchmarkSort", testBenchmarkSort),
        ("testBenchmarkRange", testBenchmarkRange),
        ("testBenchmarkSubset", testBenchmarkSubset),
        ("testBenchmarkChunking", testBenchmarkChunking),
        ("testBenchmarkAggregate", testBenchmarkAggregate),
        ("testBenchmarkLifecycle", testBenchmarkLifecycle),
        ("testBenchmarkAutoincrement", testBenchmarkAutoincrement),
        ("testBenchmarkTimestampable", testBenchmarkTimestampable),
        ("testBenchmarkJoins", testBenchmarkJoins)
    ]

    var benchmarker: Benchmarker<FluentMongo.MongoDatabase>!

    var database: FluentMongo.MongoDatabase!

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

    func testIndex() {
        do {
            let conn = try self.database.newConnection(on: MultiThreadedEventLoopGroup(numberOfThreads: 1)).wait()
            try User.index(on: conn).key(\.name, .descending).unique(true).create().wait()
            XCTAssertNoThrow(try User(name: "asdf", age: 42).save(on: conn).wait())
            XCTAssertThrowsError(try User(name: "asdf", age: 58).save(on: conn).wait())
            try User.index(on: conn).key(\.name, .descending).drop().wait()
            XCTAssertNoThrow(try User(name: "asdf", age: 58).save(on: conn).wait())
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    // Can be replaced with testBenchmarkModels once https://github.com/vapor/fluent/pull/603 is fixed
    func testModels() {
        do {
            let conn = try self.database.newConnection(on: MultiThreadedEventLoopGroup(numberOfThreads: 1)).wait()

            // create
            let a = try User(name: "asdf", age: 42).save(on: conn).wait()
            let b = try User(name: "asdf", age: 42).save(on: conn).wait()

            XCTAssertEqual(try User.query(on: conn).count().wait(), 2)

            // update
            b.name = "fdsa"
            _ = try b.save(on: conn).wait()
            _ = try User.query(on: conn).filter(\User._id == a._id).update(\.age, to: 314).run().wait()

            // read
            XCTAssertEqual(try User.find(b.requireID(), on: conn).wait()?.name, "fdsa")

            // make sure that AND queries work as expected - this query should return exactly one result
            XCTAssertEqual(try User.query(on: conn)
                .group(.and) { and in
                    and.filter(\User.name == "asdf")
                    and.filter(\User.age == 314)
                }
                .all().wait().count, 1)

            // make sure that OR queries work as expected - this query should return exactly two results
            XCTAssertEqual(try User.query(on: conn)
                .group(.or) { or in
                    or.filter(\User.name == "asdf")
                    or.filter(\User.name == "fdsa")
                }
                .all().wait().count, 2)

            // delete
            XCTAssertNoThrow(try b.delete(on: conn).wait())
            XCTAssertEqual(try User.query(on: conn).count().wait(), 1)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testJoin() {
        do {
            let conn = try self.database.newConnection(on: MultiThreadedEventLoopGroup(numberOfThreads: 1)).wait()

            let ball = try Toy(name: "ball").save(on: conn).wait()
            let bone = try Toy(name: "bone").save(on: conn).wait()
            let puppet = try Toy(name: "puppet").save(on: conn).wait()

            let molly = try Pet(name: "Molly", age: 2, favoriteToyId: ball.requireID())
                .save(on: conn)
                .wait()
            let rex = try Pet(name: "Rex", age: 1).save(on: conn).wait()

            // Relationships
            XCTAssertNotNil(try molly.favoriteToy?.get(on: conn).wait())
            XCTAssertNil(try rex.favoriteToy?.get(on: conn).wait())

            // Inner Join
            let toysFavoritedByPets = try Toy
                .query(on: conn)
                .key(\.name)
                .join(\Pet.favoriteToyId, to: Toy.idKey, method: .inner)
                .all()
                .wait()

            XCTAssertEqual(toysFavoritedByPets.count, 1)
            XCTAssertEqual(toysFavoritedByPets.first?._id, ball._id)

            // Outer Join
            let toysNotFavoritedByPets = try Toy
                .query(on: conn)
                .key(\.name)
                .join(\Pet.favoriteToyId, to: Toy.idKey, method: .outer)
                .filter(Pet.idKey == nil)
                .all()
                .wait()
                //.filter(Pet.self, Pet.idKey, .equals, nil)
                //.all([.raw("name", [])])

            XCTAssertEqual(toysNotFavoritedByPets.count, 2)
            XCTAssertTrue(toysNotFavoritedByPets.contains(where: { $0._id == bone._id }))
            XCTAssertTrue(toysNotFavoritedByPets.contains(where: { $0._id == puppet._id }))
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

    func testMigration() {
        do {
            let conn = try self.database.newConnection(on: MultiThreadedEventLoopGroup(numberOfThreads: 1)).wait()
            try MongoDatabase.prepareMigrationMetadata(on: conn).wait()
            _ = try User(name: "Alice", age: 20).save(on: conn).wait()
            _ = try User(name: "Bob", age: 20).save(on: conn).wait()
            _ = try User(name: "Charlie", age: 20).save(on: conn).wait()
            _ = try User(name: "Bob", age: 19).save(on: conn).wait()
            _ = try User(name: "Charlie", age: 20).save(on: conn).wait()

            try User.SetAgeMigration.prepare(on: conn).wait()
            XCTAssertEqual(try User.query(on: conn).filter(\.age == 99).count().wait(), 5)
            try User.SetAgeMigration.revert(on: conn).wait()
            XCTAssertEqual(try User.query(on: conn).filter(\.age == nil).count().wait(), 5)
            try MongoDatabase.revertMigrationMetadata(on: conn).wait()
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    /*
    func testBenchmarkModels() {
        do {
            https://github.com/vapor/fluent/pull/603
            try self.benchmarker.benchmarkModels()
        } catch {
            XCTFail(error.localizedDescription)
        }
    }*/

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

    func testBenchmarkTimestampable() {
        do {
            try self.benchmarker.benchmarkTimestampable()
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testBenchmarkJoins() {
        do {
            try self.benchmarker.benchmarkJoins()
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    /** Implement when we implementing

    func testBenchmarkTransaction() {
        do {
            try self.benchmarker.benchmarkTransaction()
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testBenchmarkSoftDeletable() {
        do {
            try self.benchmarker.benchmarkSoftDeletable()
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    */
}
