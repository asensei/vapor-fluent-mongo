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

    var benchmarker: Benchmarker<MongoDatabase>!

    var database: MongoDatabase!

    override func setUp() {
        let eventLoop = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        let config = try! MongoDatabaseConfig(
            host: "localhost",
            port: 27017,
            database: "vapor_database"
        )
        do {
            try MongoClient(connectionString: config.connectionURL.absoluteString).db(config.database).drop()
        } catch {
            XCTFail(error.localizedDescription)
        }
        self.database = MongoDatabase(config: config)
        self.benchmarker = try! Benchmarker(self.database, on: eventLoop, onFail: XCTFail)
    }

    func testCreate() throws {
        let eventLoop = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        let conn = try self.database.newConnection(on: eventLoop).wait()
        //try MyPet.query(on: conn).delete()
        //let all = try MyPet.query(on: conn).filter(\.name == "Sparky").all().wait()
        //let pet = MyPet(name: "Molly")
        //let sis = MyPet(name: "Rex")
        //pet.sister = sis
        //_ = try pet.save(on: conn).wait()
        //let id = try pet.requireID()
//MyPet.query(on: conn).
        //let fetch = try MyPet.query(on: conn).project(field: \._id).all().wait()
        //let fetch = try MyPet.query(on: conn).project(field: \._id).decode(data: MyTest.self).all().wait()
        //let fetch = try MyPet.query(on: conn).project(MyTest.self).all().wait()
        //let fetch = try MyPet.query(on: conn).keys(for: MyTest.self).all().wait()
        let fetch = try MyPet.query(on: conn).filter(\.name == "val").count().wait()//sum(\.legs).wait()
        XCTAssertNotNil(fetch)
        //try MyPet.query(on: conn).update(\.name, to: "Rex").run().wait()
        //pet.name = "Sparky"
        //_ = try pet.save(on: conn).wait()
    }

    struct MyTest: Codable {
        //let _id: UUID
        let name: String?
    }

    func testMongo() throws {
        let c = try MongoClient(connectionString: "mongodb://127.0.0.1", options: nil)
        let d = try c.db("vapor_database")
        let coll = try d.collection("MyPet")
        let gte: Document = ["$gte": 2]
        let options = FindOptions(projection: ["_id"])
        let sum: Document = ["$sum": "$age"]
        let newField: Document = ["_id": NSNull(), "totalAge": sum]
        let group: Document = ["$group": newField]
        //let model = try coll.find(["age": gte], options: options)
        let result = try coll.aggregate([group])
        //print(model)
        print(result.next())
    }

    struct OptionalsStruct: Codable, Equatable {
        let int: Int?
        let bool: Bool?
        let string: String

        public static func == (lhs: OptionalsStruct, rhs: OptionalsStruct) -> Bool {
            return lhs.int == rhs.int && lhs.bool == rhs.bool && lhs.string == rhs.string
        }
    }

    struct GenericStruct<C: Codable & Equatable>: Codable, Equatable {
        let value: C
    }

    func testBenchmarkModels() {
        do {
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

public final class MyPet: FluentMongoModel {

    public typealias Database = MongoDatabase

    public typealias ID = UUID

    /// Foo's identifier
    public var _id: UUID?

    /// Name string
    var name: String

    var legs: Int? = nil

    /// Age int
    var ownerID: UUID?

    var sister: MyPet? = nil

    /// Creates a new `Pet`
    init(_id: UUID? = nil, name: String, ownerID: UUID? = nil) {
        self._id = _id
        self.name = name
        self.ownerID = ownerID
    }
}
