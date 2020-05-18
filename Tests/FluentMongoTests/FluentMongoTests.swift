//
//  FluentMongoTests.swift
//  FluentMongoTests
//
//  Created by Valerio Mazzeo on 21/10/2019.
//  Copyright © 2019 Asensei Inc. All rights reserved.
//

import XCTest
import NIO
import Logging
import FluentBenchmark
import FluentKit
import MongoSwift
@testable import FluentMongo

final class FluentMongoTests: XCTestCase {

    var benchmarker: FluentBenchmarker {
        return .init(databases: self.dbs)
    }
    var eventLoopGroup: EventLoopGroup!
    var threadPool: NIOThreadPool!
    var dbs: Databases!
    var db: Database {
        self.benchmarker.database
    }
    var mongo: FluentMongo.MongoDatabase {
        self.db as! FluentMongo.MongoDatabase
    }

    override func setUpWithError() throws {
        try super.setUpWithError()

        XCTAssert(isLoggingConfigured)
        self.eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        self.threadPool = NIOThreadPool(numberOfThreads: 1)
        self.dbs = Databases(threadPool: threadPool, on: self.eventLoopGroup)

        let configuration = try! MongoConfiguration(
            host: "localhost",
            port: 27017,
            database: "vapor_database"
        )

        try MongoClient(configuration.connectionURL.absoluteString, using: self.eventLoopGroup)
            .db(configuration.database)
            .drop()
            .wait()

        try self.dbs.use(.mongo(connectionURL: configuration.connectionURL), as: .mongo)
    }

    override func tearDownWithError() throws {
        self.dbs.shutdown()
        try self.threadPool.syncShutdownGracefully()
        try self.eventLoopGroup.syncShutdownGracefully()

        try super.tearDownWithError()
    }

//    func testAll() throws { try self.benchmarker.testAll() }
//    func testAggregate() throws { try self.benchmarker.testAggregate() }
//    func testArray() throws { try self.benchmarker.testArray() }
//    func testBatch() throws { try self.benchmarker.testBatch() }
//    func testChildren() throws { try self.benchmarker.testChildren() }
//    func testChunk() throws { try self.benchmarker.testChunk() }
//    func testCRUD() throws { try self.benchmarker.testCRUD() }
//    func testEagerLoad() throws { try self.benchmarker.testEagerLoad() }
//    func testEnum() throws { try self.benchmarker.testEnum() }
//    func testFilter() throws { try self.benchmarker.testFilter() }
//    func testGroup() throws { try self.benchmarker.testGroup() }
//    func testID() throws { try self.benchmarker.testID() }
//    func testJoin() throws { try self.benchmarker.testJoin() }
//    func testMiddleware() throws { try self.benchmarker.testMiddleware() }
//    func testMigrator() throws { try self.benchmarker.testMigrator() }
//    func testModel() throws { try self.benchmarker.testModel() }
//    func testOptionalParent() throws { try self.benchmarker.testOptionalParent() }
//    func testPagination() throws { try self.benchmarker.testPagination() }
//    func testParent() throws { try self.benchmarker.testParent() }
//    func testPerformance() throws { try self.benchmarker.testPerformance() }
//    func testRange() throws { try self.benchmarker.testRange() }
//    func testSet() throws { try self.benchmarker.testSet() }
//    func testSiblings() throws { try self.benchmarker.testSiblings() }
//    func testSoftDelete() throws { try self.benchmarker.testSoftDelete() }
//    func testSort() throws { try self.benchmarker.testSort() }
//    func testTimestamp() throws { try self.benchmarker.testTimestamp() }
//    func testTransaction() throws { try self.benchmarker.testTransaction() }
//    func testUnique() throws { try self.benchmarker.testUnique() }
}

func env(_ name: String) -> String? {
    return ProcessInfo.processInfo.environment[name]
}

let isLoggingConfigured: Bool = {
    LoggingSystem.bootstrap { label in
        var handler = StreamLogHandler.standardOutput(label: label)
        handler.logLevel = .debug
        return handler
    }
    return true
}()
