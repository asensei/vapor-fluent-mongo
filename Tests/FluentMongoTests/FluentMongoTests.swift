//
//  FluentMongoTests.swift
//  FluentMongoTests
//
//  Created by Valerio Mazzeo on 30/11/2018.
//  Copyright © 2018 Asensei Inc. All rights reserved.
//

import XCTest
import NIO
import MongoSwift
import FluentKit
@testable import FluentMongo

class FluentMongoTests: XCTestCase {

    var eventLoopGroup: EventLoopGroup!
    var threadPool: NIOThreadPool!
    var dbs: Databases!

    var database: Database {
        self.dbs.database(
            logger: .init(label: "com.asensei.FluentMongoTests"),
            on: self.dbs.eventLoopGroup.next()
        )!
    }

    override func setUpWithError() throws {
        try super.setUpWithError()

        XCTAssert(isLoggingConfigured)
        self.eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        self.threadPool = NIOThreadPool(numberOfThreads: 1)
        self.dbs = Databases(threadPool: self.threadPool, on: self.eventLoopGroup)

        try clearDatabase("\(mongoConnectionString)/vapor_database", on: self.eventLoopGroup)

        try self.dbs.use(.mongo(connectionString: "\(mongoConnectionString)/vapor_database"), as: .mongo)
    }

    override func tearDownWithError() throws {
        self.dbs.shutdown()
        try self.threadPool.syncShutdownGracefully()
        try self.eventLoopGroup.syncShutdownGracefully()

        try super.tearDownWithError()
    }

    func testIndex() {
        do {
            let database = self.database
            try User.index(on: database).key(\.$name, .descending).unique(true).create().wait()
            XCTAssertNoThrow(try User(name: "asdf", age: 42).save(on: database).wait())
            XCTAssertThrowsError(try User(name: "asdf", age: 58).save(on: database).wait())
            try User.index(on: database).key(\.$name, .descending).drop().wait()
            XCTAssertNoThrow(try User(name: "asdf", age: 58).save(on: database).wait())
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testNestedIndexUsingDotNotation() {
        do {
            let database = self.database
            try User.index(on: database).key("nested.p1", .descending).unique(true).create().wait()
            XCTAssertNoThrow(try User(name: "a", nested: .init(p1: "a")).save(on: database).wait())
            XCTAssertThrowsError(try User(name: "b", nested: .init(p1: "a")).save(on: database).wait())
            try User.index(on: database).key("nested.p1", .descending).drop().wait()
            XCTAssertNoThrow(try User(name: "c", nested: .init(p1: "a")).save(on: database).wait())
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testNestedIndexUsingKeyNames() {
        do {
            let database = self.database
            try User.index(on: database).key(["nested", "p1"], .descending).unique(true).create().wait()
            XCTAssertNoThrow(try User(name: "a", nested: .init(p1: "a")).save(on: database).wait())
            XCTAssertThrowsError(try User(name: "b", nested: .init(p1: "a")).save(on: database).wait())
            try User.index(on: database).key(["nested", "p1"], .descending).drop().wait()
            XCTAssertNoThrow(try User(name: "c", nested: .init(p1: "a")).save(on: database).wait())
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testError() throws {
        let database = self.database
        let uuid = UUID()
        XCTAssertNoThrow(try User(id: uuid, name: "asdf", age: 42).create(on: database).wait())

        XCTAssertThrowsError(try User(id: uuid, name: "asdf", age: 42).create(on: database).wait(), "duplicatedKey") { error in
            guard
                let connectionError = error as? FluentMongo.Error,
                case .duplicatedKey = connectionError
                else {
                    XCTFail("\(error) is not equal to FluentMongo.Error.duplicatedKey")

                    return
            }
        }
    }

    func testFilterCollectionInSubset() {
        do {
            let database = self.database

            XCTAssertNoThrow(try User(name: "User1", nicknames: ["a", "b", "c"]).save(on: database).wait())
            XCTAssertNoThrow(try User(name: "User2", nicknames: ["b", "c", "d"]).save(on: database).wait())

            let r0 = try User.query(on: database).filter(\.$nicknames, .equal, ["a"]).all().wait()
            XCTAssertEqual(r0.count, 0)

            let r1 = try User.query(on: database).group(.and) { group in
                group.filter(\.$nicknames, .subset(inverse: false), ["a"])
                group.filter(\.$nicknames, .subset(inverse: false), ["b"])
                group.filter(\.$nicknames, .subset(inverse: false), ["c"])
            }.all().wait()

            XCTAssertEqual(r1.count, 1)
            XCTAssertEqual(r1.first?.name, "User1")

            let r2 = try User.query(on: database).filter(\.$nicknames, .subset(inverse: false), "a").all().wait()
            XCTAssertEqual(r2.count, 1)
            XCTAssertEqual(r2.first?.name, "User1")
            XCTAssertEqual(try User.query(on: database).filter(\.$nicknames ~~ "a").all().wait(), r2)

            let r3 = try User.query(on: database).filter(\.$nicknames, .subset(inverse: false), "b").all().wait()
            XCTAssertEqual(r3.count, 2)
            XCTAssertEqual(try User.query(on: database).filter(\.$nicknames ~~ "b").all().wait(), r3)

            let r4 = try User.query(on: database).filter(\.$nicknames, .subset(inverse: false), ["a", "b"]).all().wait()
            XCTAssertEqual(r4.count, 2)
            // TODO: https://github.com/vapor/fluent-kit/issues/289
            // XCTAssertEqual(try User.query(on: database).filter(\.$nicknames ~~ ["a", "b"]).all().wait(), r4)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testAddToSet() {
        do {
            let database = self.database

            var alice = User(name: "Alice", age: 42, nicknames: [])
            try alice.create(on: database).wait()
            var bob = User(name: "Bob", age: 42, nicknames: ["b"])
            try bob.create(on: database).wait()

            XCTAssertNoThrow(try User.query(on: database).filter(\.$id == alice.requireID()).set(\.$nicknames, addToSet: ["al"]).update().wait())
            XCTAssertNoThrow(try User.query(on: database).filter(\.$id == bob.requireID()).set(\.$nicknames, addToSet: ["a", "b", "c"]).update().wait())

            alice = try User.find(alice.requireID(), on: database).wait()!
            bob = try User.find(bob.requireID(), on: database).wait()!

            XCTAssertEqual(alice.nicknames, ["al"])
            XCTAssertEqual(bob.nicknames, ["a", "b", "c"])
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testPush() {
        do {
            let database = self.database

            var alice = User(name: "Alice", age: 42, names: [])
            try alice.create(on: database).wait()
            var bob = User(name: "Bob", age: 42, names: ["b"])
            try bob.create(on: database).wait()

            XCTAssertNoThrow(try User.query(on: database).filter(\.$id == alice.requireID()).set(\.$names, push: ["al"]).update().wait())
            XCTAssertNoThrow(try User.query(on: database).filter(\.$id == bob.requireID()).set(\.$names, push: ["a", "b", "c"]).update().wait())

            alice = try User.find(alice.requireID(), on: database).wait()!
            bob = try User.find(bob.requireID(), on: database).wait()!

            XCTAssertEqual(alice.names, ["al"])
            XCTAssertEqual(bob.names, ["b", "a", "b", "c"])
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testPullAll() {
        do {
            let database = self.database

            var alice = User(name: "Alice", age: 42, nicknames: [])
            try alice.create(on: database).wait()
            var bob = User(name: "Bob", age: 42, nicknames: ["a", "b", "c"])
            try bob.create(on: database).wait()
            var charlie = User(name: "Charlie", age: 42, nicknames: ["d", "e", "f", "e"])
            try charlie.create(on: database).wait()

            XCTAssertNoThrow(try User.query(on: database).filter(\.$id == alice.requireID()).set(\.$nicknames, pullAll: ["al"]).update().wait())
            XCTAssertNoThrow(try User.query(on: database).filter(\.$id == bob.requireID()).set(\.$nicknames, pullAll: ["a", "b", "c"]).update().wait())
            XCTAssertNoThrow(try User.query(on: database).filter(\.$id == charlie.requireID()).set(\.$nicknames, pullAll: ["d", "e"]).update().wait())

            alice = try User.find(alice.requireID(), on: database).wait()!
            bob = try User.find(bob.requireID(), on: database).wait()!
            charlie = try User.find(charlie.requireID(), on: database).wait()!

            XCTAssertEqual(alice.nicknames, [])
            XCTAssertEqual(bob.nicknames, [])
            XCTAssertEqual(charlie.nicknames, ["f"])
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testJoin() {
        do {
            let database = self.database

            let ball = Toy(name: "ball")
            try ball.save(on: database).wait()

            let bone = Toy(name: "bone")
            try bone.save(on: database).wait()

            let puppet = Toy(name: "puppet")
            try puppet.save(on: database).wait()

            let molly = Pet(name: "Molly", age: 2, favoriteToyId: try ball.requireID())
            try molly.save(on: database).wait()

            let rex = Pet(name: "Rex", age: 1)
            try rex.save(on: database).wait()

            // Relationships
            XCTAssertNotNil(try molly.$favoriteToy.get(on: database).wait())
            XCTAssertNil(try rex.$favoriteToy.get(on: database).wait())

            // Inner Join
            let toysFavoritedByPets = try Toy
                .query(on: database)
                .field(\.$id)
                .field(\.$name)
                .join(Pet.self, on: \Toy.$id == \Pet.$favoriteToy.$id, method: .inner)
                .all()
                .wait()

            XCTAssertEqual(toysFavoritedByPets.count, 1)
            XCTAssertEqual(toysFavoritedByPets.first?.id, ball.id)

            // Outer Join
            let toysNotFavoritedByPets = try Toy
                .query(on: database)
                .field(\.$id)
                .field(\.$name)
                .join(Pet.self, on: \Toy.$id == \Pet.$favoriteToy.$id, method: .outer)
                .filter(Pet.self, \.$id == .null)
                .all()
                .wait()

            XCTAssertEqual(toysNotFavoritedByPets.count, 2)
            XCTAssertTrue(toysNotFavoritedByPets.contains(where: { $0.id == bone.id }))
            XCTAssertTrue(toysNotFavoritedByPets.contains(where: { $0.id == puppet.id }))
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testDistinct() {
        do {
            let database = self.database
            _ = try User(name: "Alice", age: 20).save(on: database).wait()
            _ = try User(name: "Bob", age: 20).save(on: database).wait()
            _ = try User(name: "Charlie", age: 20).save(on: database).wait()
            _ = try User(name: "Bob", age: 19).save(on: database).wait()
            _ = try User(name: "Charlie", age: 20).save(on: database).wait()

            XCTAssertEqual(try User.query(on: database).count().wait(), 5)
            XCTAssertEqual(try User.query(on: database).unique().count().wait(), 5)
            XCTAssertEqual(try User.query(on: database).unique().field(\.$name).count().wait(), 3)
            XCTAssertEqual(try User.query(on: database).unique().field(\.$name).field(\.$age).count().wait(), 4)
            let users = try User.query(on: database).unique().field(\.$name).all().wait().map { $0.name }
            XCTAssertEqual(users.count, 3)
            XCTAssertTrue(users.contains("Alice"))
            XCTAssertTrue(users.contains("Bob"))
            XCTAssertTrue(users.contains("Charlie"))
            let usersNameAge = try User.query(on: database).unique().field(\.$name).field(\.$age).all().wait()
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
            let database = self.database
            _ = try User(name: "Alice", age: 20).save(on: database).wait()
            _ = try User(name: "Bob", age: 20).save(on: database).wait()
            _ = try User(name: "Charlie", age: 20).save(on: database).wait()
            _ = try User(name: "Bob", age: 19).save(on: database).wait()
            _ = try User(name: "Charlie", age: 20).save(on: database).wait()

            try User.SetAgeMigration().prepare(on: database).wait()
            XCTAssertEqual(try User.query(on: database).filter(\.$age == 99).count().wait(), 5)
            try User.SetAgeMigration().revert(on: database).wait()
            XCTAssertEqual(try User.query(on: database).filter(\.$age == nil).count().wait(), 5)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
}
