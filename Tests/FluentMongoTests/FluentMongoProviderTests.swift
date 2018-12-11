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
        self.database = MongoDatabase(config: config)
        self.benchmarker = try! Benchmarker(self.database, on: eventLoop, onFail: XCTFail)
    }

    func testCreate() throws {
        let eventLoop = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        let conn = try self.database.newConnection(on: eventLoop).wait()
        //try MyPet.query(on: conn).delete()

        let pet = MyPet(name: "Molly")
        //let sis = MyPet(name: "Rex")
        //pet.sister = sis
        _ = try pet.save(on: conn).wait()
        let id = try pet.requireID()
/*
        let fetch = try MyPet.find(id, on: conn).wait()
        XCTAssertNotNil(fetch)*/
        try MyPet.query(on: conn).update(\.name, to: "Rex").run().wait()
        //pet.name = "Rex"
        //_ = try pet.save(on: conn).wait()
    }

    func testBenchmark() throws {
        let c = try MongoClient(connectionString: "mongodb://127.0.0.1", options: nil)
        let d = try c.db("vapor_database")
        let coll = try d.collection("MyPet")
        let gte: Document = ["$gte": 2]
        let options = FindOptions(projection: ["_id"])
        let model = try coll.find(["age": gte], options: options)
        //print(model)
        print(model.next())
    }
}

public final class MyPet: FluentMongoModel {

    public typealias Database = MongoDatabase

    public typealias ID = UUID

    /// Foo's identifier
    public var _id: UUID?

    /// Name string
    var name: String

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
